class Api::V1::ServersController < Api::V1::ApiController
  respond_to :json, :xml

  def index
    @servers = Server.all
    @servers.each do |server|
      if server.managed == true
        server.address = server.server_image.host_machine.address
      end
    end
    respond_with @servers, except: :rcon_password
  end

  def show
    @server = Server.find(params[:id])
    if @server.managed == true
      @server.address = @server.server_image.host_machine.address
    end
    respond_with @server, except: :rcon_password
  end
end
