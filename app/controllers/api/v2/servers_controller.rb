class Api::V2::ServersController < Api::V2::ApiController
  before_action :user_auth

  def update
    params.permit!
    server = Server.find(params[:id])
    match = server.match

    if params[:event] == 'server_shutdown'
      server.update_attributes(state: 'stopping') if server.managed?
    elsif params[:event] == 'server_start'
      server.update_attributes(state: 'running') if server.managed?
    end
    return unless match
    if params[:event] == 'logstf_upload'
      return if params[:logstf_id].to_i == 123456 #POST test id
      return unless match.state == 'in_progress' && %w(playing halftime postgame).include?(match.current_map.state)
      match.current_map.parse_logstf(params[:logstf_id].to_i, !params[:in_match].to_bool)
      matchmap = match.current_map.reload
      matchmap.score_display(true)
      match.what_next

    elsif params[:event] == 'match_start'
      match.update(state: 'in_progress') #match state should already be in_progress, but just in case
      matchmap = match.current_map
      if matchmap.do_goldencap && !matchmap.is_won && %w(halftime postgame).include?(matchmap.state)
        matchmap.update(state: 'golden_cap')
        server.prettychat("Golden cap for match #{match.match_code} is live! Team to win this round takes the game!")
      else
        matchmap.update(state: 'playing')
        teams_string = "#{match.teams.order(:id).first.name} vs. #{match.teams.order(:id).last.name}"
        if match.match_map_ids.count > 1
          map_string = "Map #{(matchmap.part_of_set) + 1} of #{match.match_map_ids.count}:"
        else
          map_string = "Map:"
        end
        if matchmap.map_rules.is_stopwatch
          round_string = "Round #{matchmap.score.map{|team,score| score}.sum + 1}, "
        else
          round_string = " "
        end
        server.prettychat("Match #{match.match_code} is live! #{map_string} #{matchmap.map}, #{round_string}#{teams_string}")
        matchmap.score_display if matchmap.current_winner_score > 0 #if a score is greater than 0, display it to the server
      end
    end

    expose true
  end

  private

  def user_auth
    error! :unauthenticated unless @auth_type == 'server'
  end
end
