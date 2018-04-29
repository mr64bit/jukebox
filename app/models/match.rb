class Match < ActiveRecord::Base
  require('rocket_pants')
  include AASM
  include RocketPants::Cacheable
  has_one :server
  has_and_belongs_to_many :teams
  belongs_to :tournament
  has_many :match_maps, -> { order(:part_of_set)}
  accepts_nested_attributes_for :match_maps, allow_destroy: true
  serialize :score
  attr_accessor :state_event

  aasm column: "state" do
    state :waiting, default: true
    state :no_server
    state :preparing_server
    state :server_ready
    state :in_progress
    state :ended
    state :canceled

    event :cancel_match do
      transitions to: :canceled
      after do
        if self.server
          server.clear_server
          server.update(match_id: nil)
        end
      end
    end
  end

  rails_admin do
    list do
      field :id
      field :match_code
      field :state, :state
      field :starts_at do label 'Time (UTC)' end
      field :match_maps
      field :teams
      field :server
    end
    show do
      field :id
      field :match_code
      field :state, :state
      field :starts_at do label 'Time (UTC)' end
      field :region
      field :match_maps
      field :teams
      field :server
    end
    edit do
      field :id do read_only true end
      field :state do read_only true end
      field :match_code
      field :starts_at do label 'Time (UTC)' end
      field :region
      field :match_maps
      field :teams do removable true end
    end
    create do
      field :id do read_only true end
      field :state do read_only true end
      field :match_code
      field :starts_at do label 'Time (UTC)' end
      field :region
      field :match_maps
      field :teams do removable true end
    end

    state({
              states: ApplicationHelper.resize_state_labels({waiting: 'label-default', preparing_server: 'label-info', server_ready: 'label-info', in_progress: 'label-primary', ended: 'label-success', canceled: 'label-warning', no_server: 'label-warning'}, 'font-size: 100%;'),
              events: {cancel_match: 'btn-danger btn-xs'}
          })
  end

  scope :need_setup, -> { where(state: 'waiting').where('starts_at < ?', (Time.now.utc + Match.pre_match_time)) }
  scope :to_notify, -> { where('updated_at > ?', (Time.now.utc - 15.seconds)).where('created_at < ?', (Time.now.utc - 15.seconds))}

  validates :state, presence: true
  validates :match_code, presence: true
  validates :starts_at, presence: true
  validates :region, inclusion: { in: :region_enum }


  before_create :initialize_score
  after_commit :event_checker

  @@game_formats = Hashugar.new(
      "name" => {
          players_per_team: 9, #not used for anything atm
          item_whitelist: 'whitelist.txt', #will be overwritten by config file on server
          exec_prefix: nil, #if not nil, will be used as the prefix for exec'd configs instead of the format name
          gamemodes: {
              "gamemode" => { #map name prefix, without the underscore. (cp, pl, koth, etc.)
                  win_difference: false,
                  win_score: 5,
                  is_stopwatch: false,
                  timelimit: 30,
                  exec_suffix: nil #if not nil, will be used as the suffix for exec'd configs instead of the gamemode name
              }
          }
      },
      "evl_hl" => {
          players_per_team: 9,
          item_whitelist: 'item_whitelist_evl_HL.txt',
          gamemodes: {
              "cp" => {
                  win_difference: false,
                  win_score: 5,
                  is_stopwatch: false,
                  timelimit: 30,
                  exec_suffix: 'standard'
              },
              "pl" => {
                  win_difference: false,
                  win_score: 2,
                  is_stopwatch: true,
                  timelimit: 0,
                  exec_suffix: 'stopwatch'
              },
              "koth" => {
                  win_difference: false,
                  win_score: 4,
                  is_stopwatch: false,
                  timelimit: 0
              }
          }
      },
      "evl_ultiduo" => {
          players_per_team: 2,
          item_whitelist: 'whitelist.txt',
          gamemodes: {
              "ultiduo" => {
                  win_difference: false,
                  win_score: 2,
                  is_stopwatch: false,
                  timelimit: 0
              }
          }
      }
  )

  def self.game_formats()
    @@game_formats
  end

  def self.pre_match_time()
    10.minutes
  end

  def region_enum
    Server.unscoped.distinct.pluck(:region)
  end

  def title
    "##{id} #{match_code}"
  end

  def match_format
    name = self.match_format_name
    game_formats = Match.game_formats[name]
    game_formats.name = name
    return game_formats
  end

  def prepare_server?()
    return((self.starts_at - Match.pre_match_time) < Time.now.utc)
  end

  def current_map()
    self.match_maps.where.not(state: 'ended').first
  end

  def find_server(prepare = false, id = nil)
    unless self.server
      if id
        server = Server.find(id)
      else
        server = Server.available.where(region: self.region).first || Server.available.first
      end
    end
    if prepare
      server.update(match_id: self.id)
      server.generate_passwords(true, server.managed?)
      self.update(state: 'preparing_server')
      ServerSetup.perform_async(self.id)
    end
    return server
  end

  def whitelist_players(rcon = nil)
    steamIDs = ''
    rcon.rcon_exec("sm_whitelist_reload") if rcon
    self.teams.each do |team|
      team.players.each do |player|
        string = "sm_whitelist_add \"#{SteamCondenser::Community::SteamId.community_id_to_steam_id3(player.steam_id)}\";"
        steamIDs << string
        if rcon
          rcon.rcon_exec(string)
          sleep 0.2
        end
      end
    end
    return steamIDs
  end

  def update_score #should be called when a match_map's state changes to 'postgame'
    maps = self.match_maps.where(:state => [:postgame, :ended])
    self.score = self.team_ids.each_with_object(Hash.new) do |team_id,hash|
       hash[team_id] = maps.map do |map|
         return 0 unless map.score
         map.score[team_id] > map.score.except(team_id).first.last ? 1 : 0
       end.sum
    end
    self.save
  end

  def is_won
    self.update_score
    return self.score.max_by{|team,score| score}.last > self.match_map_ids.count / 2
  end

  def what_next
    current_map = self.current_map
    case
      when current_map.state != 'postgame'
        #nothing needs done
      when current_map.state == 'postgame' && current_map.is_won
        if self.is_won
          if self.match_map_ids.count > 1
            self.server.prettychat("#{Team.find(self.score.max_by{|team,score| score}.first).name} wins, taking #{self.score.max_by{|team,score| score}.last} maps.")
          end
          self.server.prettychat("Match is over, server will shut down in two minutes.")
          PostMap.perform_in(2.minutes, self.id, 'shutdown')
        elsif self.match_maps.map(&:part_of_set).include?((current_map.part_of_set) +1) && current_map.is_won
          self.server.prettychat("The next map in this set is #{self.match_maps.where(part_of_set: current_map.part_of_set + 1).first.map}. Changing in two minutes.")
          PostMap.perform_in(2.minutes, self.id, 'nextmap')
        end
    end
  end

  def notify_website
    json = {match: self}.to_json(:include => {:match_maps => {}, :server => {:except => [:rcon_password, :address], :methods => :real_address}} )
    c = Curl::Easy.http_post("https://evlbr.com/api/serverbot/update/", json) do |curl|
      curl.headers['Accept'] = 'application/json'
      curl.headers['Content-Type'] = 'application/json'
    end
    return c.body_str
  end

  def create_match_maps(maps)
    existing_maps = match_maps.count
    maps.each_with_index do |map, i|
      self.match_maps.create(map: map, part_of_set: i + existing_maps)
    end
  end

  private

  def initialize_score
    self.score = Hash.new
  end

  def event_checker
    if previous_changes.include?('state') && previous_changes['state'].last == 'server_ready'
      EventLog.new_event('server_ready', self)
    end
  end
end
