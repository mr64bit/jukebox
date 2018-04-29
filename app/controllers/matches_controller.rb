class MatchesController < ApplicationController
  before_action :authenticate
  after_filter :allow_iframe
  before_filter :allow_cors

  def index
    @datatable = MatchDatatable.new(view_context)
    respond_to do |format|
      format.html
      format.json { render json: @datatable }
    end
  end

  def show
    @match = Match.find(params[:id])
    @teams = @match.teams
    @server = @match.server
  end

  private

  def authenticate
    if params[:player] == 'true'
      if session[:role] != 'player'
        request_http_basic_authentication unless authenticate_with_http_basic do |name, password|
          Rails.logger.debug "auth called"
          return_val = (name == 'player' && BCrypt::Password.new('$2a$08$78pbU23BiDka9nlEJ1AjsefjHmN5wlPfJEV4nrhh5jO.bl76Kc95G') == password)
          session[:role] = 'player' if return_val
          return_val
        end
      end
    elsif params[:player] == 'false'
      session[:role] = 'guest'
      return_val = true
    elsif session[:role] == 'player'
      return_val = true
    end
    Rails.logger.debug params[:player]
    Rails.logger.debug session[:role]
    return return_val
  end

  def allow_iframe
    response.headers.delete "X-Frame-Options"
  end

  def allow_cors
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET'
  end
end
