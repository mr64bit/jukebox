namespace :db do
  desc "Create database seeds for a vagrant box"
  task vagrant_seed: :environment do
    host = HostMachine.create(address: 'localhost', working_path: '/home/vagrant/steam', user: 'vagrant', key_path: '.vagrant/machines/default/vmware_workstation/private_key', region: 'local') #change the key_path if needed to the location of the key for your vagrant box
    image = ServerImage.create(host_machine_id: host.id)
    server = Server.create(server_image_id: image.id, hostname: 'EVL serverbot dev', managed: true)
    teams = [Team.create(name: 'Team A', tag: 'A'), Team.create(name: 'Team B', tag: 'B')]
    18.times do |i|
      Player.create(name: "Player #{i}", steam_id: 76561198067515569 + (i * 3), team_id: i.even? ? teams.first.id : teams.last.id)
    end
    match = Match.create(match_code: 'T1', starts_at: Time.now + 1.year, match_type: 'single', region: 'local', match_format_name: 'evl_hl')
    map = MatchMap.create(match_id: match.id, map: 'pl_badwater', part_of_set: 0)
    match.teams << teams
  end

end
