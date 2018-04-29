class CreateServerImage
  include Sidekiq::Worker

  def perform(id)
    image = ServerImage.find(id)
    host  = image.host_machine
    ssh   = host.ssh

    #Install the server
    ssh.exec!("#{File.join(host.working_path, 'steamcmd', 'steamcmd.sh')} +login anonymous +force_install_dir #{File.join(host.working_path, 'images', image.path)} +app_update #{image.appid} validate +quit")
    #"/var/serverbot/steamcmd/steamcmd.sh +login anonymous +force_install_dir /var/serverbot/images/tf2 +app_update 232250 validate +quit"

    #Link configs from the git repo
    ssh.exec!("#{File.join(host.working_path, 'configs', image.config_source, '.link.sh')} #{File.join(host.working_path, 'images', image.path)} #{File.join(host.working_path, 'configs', image.config_source)}")
    #"/var/serverbot/configs/tf2/.link.sh /var/serverbot/images/tf2 /var/serverbot/configs/tf2"

    image.image_ready!
    ssh.close
  end
end
