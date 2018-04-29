class Api::V1::ServerImagesController < Api::V1::ApiController
  def index
    respond_to do |format|
      format.json { render json: ServerImage.all }
      format.xml { render xml: ServerImage.all }
    end

  end

  def show
    server_image = ServerImage.find(params[:id])
    render json: server_image
  end
end
