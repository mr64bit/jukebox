class Api::V1::MatchesController < Api::V1::ApiController
  respond_to :json, :xml

  def index
    respond_with Match.all
  end

  def show
    @match = Match.find(params[:id])
    if @match.server
      if @match.server.managed == true
        @match.server.address = @match.server.server_image.host_machine.address
      end
    end
    respond_with @match, :include => { :server => { :except => :rcon_password } }
  end
end
