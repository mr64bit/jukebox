class Api::V2::MatchesController < Api::V2::ApiController
  before_action :user_auth

  def index
    expose Match.all
  end

  def show
    @match = Match.where(match_code: params[:id]).last
    expose @match, :include => { :match_maps => {}, :server => { :except => [:rcon_password, :address], :methods => :real_address }, :teams => { :include => :players } }
  end

  def create
    params.permit!
    params[:match][:starts_at] = Time.parse(params[:match][:starts_at]).utc
    begin
      @match = Match.find_or_create_by(match_code: params[:match][:match_code])
      @match.assign_attributes(params[:match].slice(:starts_at, :match_type, :region))
    rescue
      error! :bad_request
    end

    if @match.save
      error! :bad_request unless params[:match][:map].class == Array
      begin
        params[:match][:map].each_with_index do |map, index|
          match_map = MatchMap.find_or_create_by(match_id: @match.id, part_of_set: index)
          match_map.map = map if match_map.state == 'waiting'
          match_map.save
        end
      rescue
        error! :bad_request
      end

      if params['ignore_players']
        params['match']['teams'].each do |team|
          @match.teams << Team.find(team)
        end
      else
        params['match']['teams'].each do |team|
          @team = Team.find_or_create_by(id: team['id'])
          @team.update(team.slice('name', 'tag'))
          @match.teams << @team unless @match.team_ids.include?(@team.id)
          team['players'].each do |player|
            @player = Player.find_or_create_by(steam_id: player['steam_id'])
            @player.name = player['name']
            @player.team_id = @team.id
            @player.save
          end
          @team.players.each{|player| player.update(team_id: nil) unless team['players'].find{|team_player| player.steam_id == (team_player['steam_id'] || team_player['steam_id'].to_i)}} #remove players that aren't on this team anymore
        end
        @match.teams.each{|team| @match.teams.delete(team.id) unless params['match']['teams'].find{|params_team| params_team['id'] == team.id}} #remove teams that aren't in this match anymore
      end
      @match.update(score: @match.team_ids.each_with_object(Hash.new){|team_id,hash| hash[team_id] = 0})
      @match.match_maps.each{|match_map| match_map.update(score: @match.team_ids.each_with_object(Hash.new){|team_id,hash| hash[team_id] = 0})}
      @match.find_server(true) if @match.prepare_server? && !@match.server
      expose @match.reload, :include => { :match_maps => {}, :server => { :except => [:rcon_password, :address], :methods => :real_address }, :teams => { :include => :players } }
    else
      error! :bad_request
    end
  end

  def destroy
    match = Match.where(match_code: params['match']['match_code']).last
    match.update(state: 'canceled')
    match.match_maps.update_all(state: 'ended')
    if match.server
      match.server.prettychat("Match #{match.match_code} has been canceled. Go to evlbr.com for more information.")
      match.server.clear_server
      match.server.update(match_id: nil)
    end
    expose "match #{match.id} successfully cancelled"
  end

  private

  def user_auth
    error! :unauthenticated unless @auth_type == 'web'
  end
end
