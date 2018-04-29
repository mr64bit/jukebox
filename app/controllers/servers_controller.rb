class ServersController < ApplicationController
  def index
    @active_servers = (Server.where.not(num_players: 0).order(:id) + Server.where.not(match_id: nil).order(:id)).uniq
    @inactive_servers = Server.where(match_id: nil).order(:id)
  end
end
