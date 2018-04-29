class CreateServer
  include Sidekiq::Worker

  def perform(id)
    server = Server.find(id)
    image  = server.server_image
    host   = image.host_machine
    ssh    = host.ssh

    Rails.logger.info ssh.exec!("#{File.join(host.working_path, 'configs', image.config_source, 'sourcemod.sh')} #{File.join(host.working_path, 'images', image.path)} #{server.id}")
    #"/var/serverbot/configs/tf2/sourcemod.sh /var/serverbot/images/tf2 23"
    server.server_created!
    ssh.close
  end
end
