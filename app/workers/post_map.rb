class PostMap
  include Sidekiq::Worker

  def perform(id, action)
    match = Match.find(id)
    raise "Match has no server" unless match.server
    server = match.server

    case action
      when "shutdown"
        server.clear_server
        match.update(state: 'ended')
        match.match_maps.update_all(state: 'ended')
        server.update(match_id: nil)

      when "nextmap"
        raise "Can't nextmap for matches with only one map" if match.match_map_ids.count <= 1
        current_map = match.current_map
        next_map = match.match_maps.where(part_of_set: current_map.part_of_set + 1).first
        raise "No more maps left!" unless next_map
        current_map.update(state: 'ended')
        next_map.update(state: 'pregame')
        server.prettychat("Changing map to #{next_map.map}")
        ServerSetup.perform_async(id)

      when "goldencap"
        server.rcon.rcon_exec("exec #{Server.find_cfg(match.current_map)}_overtime")
    end
  end
end
