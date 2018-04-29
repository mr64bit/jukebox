class Api::V1::HostMachinesController < Api::V1::ApiController
  respond_to :json, :xml

  def index
    respond_with HostMachine.all, except: :password
  end
end
