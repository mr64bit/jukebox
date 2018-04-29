class UpdateImage
  include Sidekiq::Worker

  def perform(id)
    image = ServerImage.find(id)
    host  = image.host_machine
    ssh   = host.ssh

    #same thing as installing, just without 'validate',
    ssh.exec!("#{File.join(host.working_path, 'steamcmd', 'steamcmd.sh')} +login anonymous +force_install_dir #{File.join(host.working_path, 'images', image.path)} +app_update #{image.appid} +quit")
    #"/var/serverbot/steamcmd/steamcmd.sh +login anonymous +force_install_dir /var/serverbot/images/tf2 +app_update 232250 +quit"
    image.image_ready!
    ssh.close
  end
end
