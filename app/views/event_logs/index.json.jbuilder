json.array!(@events) do |event|
  json.extract! event, :id, :event_type, :winning_team_score, :losing_team_score
  json.match event.match, :id, :state, :match_code, :starts_at if event.match
  if event.event_type != 'server_ready'
    json.winning_team event.winning_team, :id, :name, :tag if event.winning_team
    json.losing_team event.losing_team, :id, :name, :tag if event.losing_team
    if event.match_map
      json.match_map do
        json.extract! event.match_map, :id, :state, :map
        json.logs event.match_map.logs.map {|log| log['id']}
      end
    end
  end
end
