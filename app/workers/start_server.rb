class StartServer
  include Sidekiq::Worker

  def perform(id)
    Server.find(id).server_start
  end
end
