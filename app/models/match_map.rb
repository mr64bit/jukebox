class MatchMap < ActiveRecord::Base
  include AASM
  belongs_to :match
  serialize :score
  serialize :logs

  aasm column: 'state' do
    state :waiting, defailt: true
    state :pregame
    state :playing
    state :halftime
    state :postgame
    state :golden_cap
    state :ended
  end

  rails_admin do
    show do
      field :id
      field :match
      field :state
      field :score do
        formatted_value do
          matchmap = bindings[:object]
          "#{matchmap.current_winner_team.tag} #{matchmap.current_winner_score}-#{matchmap.current_loser_score} #{matchmap.current_loser_team.tag}"
        end
      end
      field :logs do
        formatted_value do
          matchmap = bindings[:object]
          view = bindings[:view]
          logs_array = matchmap.logs.map{|log,i| view.link_to(log['id'], "http://logs.tf/#{log['id']}")}
          !logs_array.empty? ? logs_array.join(', ').html_safe : ''
        end
      end
      field :part_of_set
    end
    edit do
      field :id do read_only true end
      field :state do read_only true end
      field :map
      field :score
      field :logs
      field :part_of_set
    end
  end

  scope :to_notify, -> { where('updated_at > ?', (Time.now.utc - 15.seconds)).where('created_at < ?', (Time.now.utc - 15.seconds))}

  validates :map, presence: true
  validates :part_of_set, presence: true

  before_create :initialize_score
  after_commit :event_checker, on: :update

  def self.map_format(map)
    @map_cfg_exceptions = { 'cp_steel' => 'pl', 'cp_gravelpit' => 'pl', 'koth_ultiduo_r_b7' => 'ultiduo'} #TODO: make something so wildcard/partial map names will work. For example, 'koth_viaduct_*' should match any version
    return @map_cfg_exceptions[map] || map.split('_')[0]
  end

  def title
    "##{id} (#{map})"
  end

  def map_rules
    @prefix = MatchMap.map_format(self.map)
    @rules = self.match.match_format.gamemodes[@prefix]
    @rules.name = @prefix
    return @rules
  end

  def parse_logstf(log_id, is_done = false)
    self.logs ||= Array.new
    logs_hash_tmp = self.logs.find{|hash| hash['id'] == log_id} || {'id' => log_id}
    logs_hash = logs_hash_tmp.clone
    team_ids = self.match.team_ids
    teams_for_color = {'Red' => [], 'Blue' => []}
    logs_tf = JSON.parse(Curl::Easy.perform("logs.tf/json/#{log_id}").body_str)
    logs_tf['players'].each do |steamid, player|
      localplayer = Player.where(team_id: team_ids).where(steam_id: SteamCondenser::Community::SteamId.steam_id_to_community_id(steamid)).first
      team_id = localplayer.team_id if localplayer
      teams_for_color[player['team']] << team_id if team_ids.include? team_id
    end
    team_id_counts = {'Red' => {}, 'Blue' => {}}
    teams_for_color.each do |color, counts|
      team_id_counts[color] = counts.each_with_object(Hash.new(0)){ |count, total| total[count] += 1 }
    end
    raise "No players could be found for a least one team" if team_id_counts.any?{|team, ids| ids.empty?}
    logs_hash.merge!(team_id_counts.each_with_object(Hash.new{|h,k| h[k] = {}}){|(color, counts), totals| totals[color]['team_id'] = counts.sort_by{|team, count| count}.first.first})

    if self.map_rules.is_stopwatch
      if logs_tf['rounds'].count == 2
        logs_tf['teams'].each{|team,info| logs_hash[team]['score'] = (logs_tf['rounds'].last['winner'] == team) ? 1 : 0}
      else
        logs_tf['teams'].each{|team,info| logs_hash[team]['score'] = 0}
      end
    elsif self.map_rules.name == 'cp' && self.do_goldencap
      logs_tf['teams'].each{|team,info| logs_hash[team]['score'] = (logs_tf['rounds'].first['events'].find_all{|event| event['type'] == 'pointcap' && event['point'] == 3}.last['team'] == team) ? 1 : 0}
    else
      logs_tf['teams'].each{|team,info| logs_hash[team]['score'] = info['score']}
    end
    last_win = logs_tf['rounds'].last['events'].find{|event| event['type'] == 'round_win'}
    logs_hash['is_done'] = is_done
    self.logs[self.logs.index{|hash| hash['id'] == log_id} || self.logs.count] = logs_hash
    self.score = self.match.team_ids.each_with_object(Hash.new) do |id,hash|
      hash[id] = self.logs.map{|log| log.slice('Red','Blue').find{|color,team| team['team_id'] == id}.last['score']}.sum
    end
    self.save
  end

  def is_won
    if (self.map_rules.is_stopwatch                                        && self.current_winner_score >= self.map_rules.win_score) || #map is won in a stopwatch map
       (self.map_rules.name == 'koth' || self.map_rules.name == 'ultiduo'  && self.current_winner_score >= self.map_rules.win_score)    #map is won on a KOTH map)
      return true
    elsif self.map_rules.name == 'cp' #oh boy, on a standard map
      if self.current_winner_score >= self.map_rules.win_score || (self.logs.first['is_done'] && !self.do_goldencap) #if a team has won by score or time limit and no golden cap needed
        return true
      elsif self.do_goldencap == true && self.current_winner_score > self.current_loser_score #if the golden cap has already finished
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def do_goldencap
    return false unless self.logs
    return false unless self.logs.first #something needs to exist before we check it
    if self.map_rules.name == 'cp' && self.logs.first['is_done'] == true && self.logs.first['Red']['score'] == self.logs.first['Blue']['score']
      return true
    else
      return false
    end
  end

  def current_winner_color()
    self.logs.last.slice('Red','Blue').find{|color,info|info['team_id'] == self.score.max_by{|team,score| score}.first}.first
  rescue
    "default"
  end
  def current_winner_team()
    if self.current_winner_score != self.current_loser_score
      team = Team.find(self.score.max_by{|team,score| score}.first)
    else
      team = self.match.teams.first
    end
    return team ? team : Team.dummy
  rescue
    Team.dummy
  end
  def current_winner_score()
    self.score.max_by{|team,score| score}.last
  rescue
    0
  end

  def current_loser_color()
    self.logs.last.slice('Red','Blue').find{|color,info|info['team_id'] == self.score.min_by{|team,score| score}.first}.first
  rescue
    "default"
  end
  def current_loser_team()
    if self.current_winner_score != self.current_loser_score
      team = Team.find(self.score.min_by{|team,score| score}.first)
    elsif self.match.team_ids.count == 1
      team = Team.dummy
    else
      team = self.match.teams.last
    end
    return team ? team : Team.dummy
  rescue
    Team.dummy
  end
  def current_loser_score()
    self.score.min_by{|team,score| score}.last
  rescue
    0
  end

  def short_scores
    "#{current_winner_team.tag} #{current_winner_score}-#{current_loser_score} #{current_loser_team.tag}"
  end

  def score_display(do_action = false)
    raise "No server to display scores to." unless (server = self.match.server)
    raise "No scores to display yet." unless (self.logs && self.logs.first)
    if self.is_won #hooray a team has won!
      server.prettychat("{#{self.current_winner_color}}#{self.current_winner_team.name}{default} won #{self.map} with a score of #{self.current_winner_score}-#{self.current_loser_score}!")
      self.update(state: :postgame) if do_action
    elsif self.do_goldencap #time ran out and we're tied
      server.prettychat("Time's up and the score is tied #{self.current_winner_score}-#{self.current_loser_score}! Next round will be a golden cap!")
      server.prettychat("Please wait for Golden Cap configs to be executed before readying up.") if do_action
      self.update(state: :halftime) if do_action
      PostMap.perform_in(10.seconds, self.match_id, "goldencap") if do_action

    elsif !self.map_rules.is_stopwatch || self.logs.last['is_done'] #map not won yet, show scores unless it's the first part of a stopwatch round
      self.update(state: :halftime) if self.map_rules.is_stopwatch
      if self.current_winner_score == self.current_loser_score #teams are tied
        #tell the server the tied score unless it's 0-0
        server.prettychat("Teams are tied #{self.current_winner_score}-#{self.current_loser_score}!") unless self.current_winner_score == 0
      else #not tied, say who's winning
        server.prettychat("{#{self.current_winner_color}}#{self.current_winner_team.name}{default} is leading {#{current_loser_color}}#{current_loser_team.name}{default} by #{self.current_winner_score}-#{current_loser_score}!")
      end
    end
  end

  private

  def initialize_score
    self.score = Hash.new
    self.logs = []
  end

  def event_checker
    if previous_changes.include?('state')
      if previous_changes['state'].first == 'pregame' && previous_changes['state'].last == 'playing'
        EventLog.new_event('map_start', self)
      elsif previous_changes['state'].last == 'postgame'
        EventLog.new_event('map_end', self)
      end
    end

    if previous_changes.include?('score') && !is_won
      EventLog.new_event('map_score', self)
    end
  end
end
