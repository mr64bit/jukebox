class UpdateServer #From when I was testing stuff, we'll probably use something like this in the future, but for now it doesn't do anything usefull
  include Sidekiq::Worker

  def perform(server_id)
    server = Server.find(server_id)
    rcon   = Server.rcon(server_id)
    if server.managed == false
      server.hostname    = rcon.rcon_exec('hostname').split('"')[3]
      server.sv_password = rcon.rcon_exec('sv_password').split('"')[3]
      server.game_port   = rcon.rcon_exec('clientport').split('"')[3].to_i
      server.map         = rcon.server_info[:map_name]
      server.num_players = rcon.server_info[:number_of_players]
      server.stv_port    = rcon.server_info[:tv_port]
    elsif server.managed == true
    end
    server.save
  end
end