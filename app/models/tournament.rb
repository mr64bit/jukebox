class Tournament < ActiveRecord::Base
  has_many :matches
  has_many :teams
  self.primary_key = 'id'

  def toorney
    Toorney::Tournament.find(self.id)
  end

  def update_teams
    toorney_teams = Toorney::Participant.all(_tournament_id: self.id, with_lineup: 1, with_custom_fields: 1)
    toorney_teams.each do |toorney_team|
      team = Team.find_or_initialize_by(toorney_id: toorney_team.id)
      team.name = toorney_team.name
      team.tournament_id =  self.id
      begin
        team.tag = toorney_team.custom_fields_private.find{|field| field['label'] == 'Tag'}['value']
      rescue => e
        team.tag = toorney_team.name.truncate_words(2)
        Rails.logger.warn "Could not find tag for team #{team.name} (#{team.toorney_id})"
      end
      team.save

      begin
        toorney_team.lineup.each do |toorney_player|
          begin
            id_test = SteamIdFilter.to_id64(toorney_player['custom_fields_private'].find{|field| field['type'] == 'steam_player_id'}['value'])

            if id_test
              player = Player.find_or_initialize_by(steam_id: id_test)
              player.name = toorney_player['name']
              player.team_id = team.id
              player.save
            else
              Rails.logger.warn "Could not parse steam ID for player #{toorney_player['name']}, #{id_test} (#{toorney_team.name}, #{toorney_team.id})"
            end

          rescue
            Rails.logger.warn "Could not find steam ID field for player #{toorney_player['name']} (#{toorney_team.name}, #{toorney_team.id})"
          end
        end
      rescue
        Rails.logger.warn "Could not find lineup for team #{toorney_team.id}"
      end
    end
  end

  def poll_matches
    toorney_matches = Toorney::Match.all(_tournament_id: self.id)
    toorney_matches.each do |toorney_match|
      match = Match.find_or_initialize_by(toorney_id: toorney_match.id)
      match.tournament_id = self.id
      match.toorney_id = toorney_match.id
      stage_number = toorney_match.stage_number
      group_number = toorney_match.group_number
      round_number = toorney_match.round_number
      game_number = toorney_matches.select{|o| o.stage_number == stage_number && o.group_number == group_number && o.round_number == round_number}.sort{|a,b| a.id <=> b.id}.map(&:id).index(toorney_match.id) + 1
      match.match_code = "#{stage_number}.#{group_number}.#{round_number}.#{game_number}"
      match.starts_at = Time.parse(toorney_match.date).utc
      if toorney_match.match_format =~ /bo\d+/
        match.match_type = $& #last regex match
      else
        match.match_type = 'single'
      end
      match.save

      participants = toorney_match.opponents.each_with_object([]){|opponent,array| array << opponent['participant']}
      match.teams.each do |team|
        if participants.reject(&:nil?).none?{|participant| participant['id'] == team.toorney_id}
          match.teams.delete(team)
        end
      end

      participants.reject(&:nil?).each do |participant|
        match.teams << Team.find_by_toorney_id(participant['id']) unless match.teams.any?{|team| team.toorney_id == participant['id']}
      end

      toorney_match.games.each do |game|
        match_map = MatchMap.find_or_initialize_by(match_id: match.id, part_of_set: game.number)
        match_map.map = game.map
        match_map.save
      end
    end
  end
end
