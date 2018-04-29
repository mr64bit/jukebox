class ServerSetup
  include Sidekiq::Worker

  def perform(id)
    @match = Match.find(id)
    @server = @match.server
    raise "No server for match #{@match.id}" unless @server

    @server.hostname = "EVLBR:UD Match #{@match.match_code}: #{@match.teams.first.tag} vs. #{@match.teams.last.tag} (Server #{@server.id})"
    @server.map = @match.current_map.map
    @server.save

    @server.server_start! if @server.managed && @server.state == 'stopped'

    sleep(5) until @server.reload.state == 'running'
    @server.exec_cfg(Server.find_cfg(@match.current_map))
    sleep(5) #should be long enough
    @rcon = @server.rcon
    @rcon.rcon_exec("hostname \"#{@server.hostname}\"")
    @rcon.rcon_exec("tv_name \"#{@server.hostname} STV\"")
    @rcon.rcon_exec("sv_password #{@server.sv_password}")
    @rcon.rcon_exec("logstf_title \"EVLBR:UD Match #{@match.match_code}: #{@match.teams.first.tag} vs. #{@match.teams.last.tag}\"")
    @rcon.rcon_exec("evl_server_id #{@server.id}; evl_api_password WFsxvBDyiO2ec9-K93NBQQ")
    if @match.current_map.map_rules.is_stopwatch
      @rcon.rcon_exec("evl_antiswap 1")
    else
      @rcon.rcon_exec("evl_antiswap 0")
    end
    @rcon.rcon_exec("whitelist_filename whitelist-#{@match.id}.#{@match.current_map.part_of_set}.txt")
    @rcon.rcon_exec("whitelist_kickmessage \"This server is for players in EVLBR:UD match #{@match.match_code}: #{@match.teams.first.tag} vs. #{@match.teams.last.tag} only. If you believe this is an error, please go to 'evlbr.com/chat/' for assistance\"")
    @match.whitelist_players(@rcon); sleep(1)
    @server.change_map(@match.current_map.map)

    sleep(5) until @server.reload.state == 'running'
    @match.update(state: 'server_ready')
  end
end
