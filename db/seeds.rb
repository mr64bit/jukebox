# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

host_machine = HostMachine.create(address: "localhost", working_path: "/home/steam/serverbot", user: "steam", password: "serverbotWorker")
server_image = ServerImage.create(host_machine_id: host_machine.id)
server = Server.create(hostname: "Serverbot Test", rcon_password: "serverbot", sv_password: "connect", map: "pl_badwater",  server_image_id: server_image.id, match_id: 1)
teams = [Team.create(name: 'Team A', tag: 'A'), Team.create(name: 'Team B', tag: 'B')]
18.times do |i|
  Player.create(name: "Player #{i}", steam_id: 76561198067515569 + (i * 3), team_id: i.even? ? teams.first.id : teams.last.id)
end
match = Match.create(match_code: 'T1', starts_at: Time.now + 1.year, match_type: 'single', region: 'local', match_format_name: 'evl_hl')
map = MatchMap.create(match_id: match.id, map: 'pl_badwater', part_of_set: 0)
match.teams << teams
