module Settings
  ConfigSource     = { type: "git", url: "git@configs:server-management/server-configs.git" }
  SteamcmdDownload = "http://media.steampowered.com/installer/steamcmd_linux.tar.gz"
  ApiKeys = {"web" => ENV['API_WEB'], "server" => ENV['API_SERVER']}
  CURRENT_TOURNAMENT=ENV['TOURNAMENT_ID']
end

Toorney.configuration do |c|
  c.api_key = ENV['TOORNEY_KEY']
  c.client_id = ENV['TOORNEY_ID']
  c.client_secret = ENV['TOORNEY_SECRET']
end
