class ServerTick
  include Sidekiq::Worker
  def perform
    hosts_to_check = Set.new []
    Server.all.each do |server|
      server.server_check
      hosts_to_check.add(server.server_image.host_machine_id) if server.managed == true && ['stopping'].include?(server.state)
    end

    hosts_to_check.each do |host_id|
      host = HostMachine.find(host_id)
      screens = HostMachine.parse_screens(host.ssh.exec!('screen -ls'))
      Rails.logger.debug screens
      host.servers.each do |server|
        server.update(state: 'stopped') unless screens.include?(server.id)
      end
    end

    Match.need_setup.each do |match|
      if match.team_ids.count == 2 && match.match_map_ids.count > 0
        match.find_server(true)
      else
        Rails.logger.warn("Not preparing server for match #{match.id}, match does not have two teams or has no match maps")
      end
    end

    Match.server_ready.each do |match|
      if match.server.num_players > 0
        match.update(state: 'in_progress')
        match.current_map.update(state: 'pregame')
      end
    end
  end
end
