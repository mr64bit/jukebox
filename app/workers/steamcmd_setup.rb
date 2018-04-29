class SteamcmdSetup
  include Sidekiq::Worker

  def perform(id)
    host = HostMachine.find(id)
    ssh  = host.ssh
    Rails.logger.info ssh.exec!("mkdir -p #{ File.join(host.working_path, 'steamcmd') }")
    Rails.logger.info ssh.exec!("wget -nv -P #{File.join(host.working_path, 'steamcmd') } #{ Settings::SteamcmdDownload }")
    Rails.logger.info ssh.exec!("tar xvf #{ File.join(host.working_path, 'steamcmd', 'steamcmd_linux.tar.gz') } -C #{File.join(host.working_path, 'steamcmd')}")
    Rails.logger.info ssh.exec!("#{File.join(host.working_path, 'steamcmd', 'steamcmd.sh')} +login anonymous +quit")
    Rails.logger.info ssh.exec!("mkdir $HOME/.ssh; echo \'#{File.read(File.join("config", "ssh_config"))}\' >> $HOME/.ssh/config")
    Rails.logger.info ssh.exec!("echo \'#{File.read(File.join("config", "deploy_rsa"))}\' > $HOME/.ssh/deploy_rsa")
    Rails.logger.info ssh.exec!("chmod 600 $HOME/.ssh/*")
    Rails.logger.info ssh.exec!("ssh -T git@configs -o StrictHostKeyChecking=no")
    Rails.logger.info ssh.exec!("git clone #{Settings::ConfigSource[:url]} #{File.join(host.working_path, 'configs')}")
    Rails.logger.info ssh.exec!("chmod u+x,g+x #{File.join(host.working_path, 'configs', 'tf2/.link.sh')} #{File.join(host.working_path, 'configs', 'tf2/sourcemod.sh')}")
    host.install_completed!
    ssh.close
  end
end
