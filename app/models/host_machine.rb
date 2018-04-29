class HostMachine < ActiveRecord::Base
  include AASM
  has_many :server_images
  has_many :servers, through: :server_images

  aasm column: "state" do
    state :clean, :initial => true
    state :installing
    state :installed

    event :install_steamcmd do
      transitions from: :clean, to: :installing
      after do
        SteamcmdSetup.perform_async(self.id)
      end
    end
    event :install_completed do
      transitions from: :installing, to: :installed
    end
  end

  def ssh() #Returns an SSH object connected to the host_machine it was called from.
    begin
      if self.key_path && !self.key_path.empty?
        @ssh = Net::SSH.start(self.address, self.user, keys: [self.key_path], port: self.port, timeout: 5, number_of_password_prompts: 0)
      elsif self.password && !self.password.empty?
        @ssh = Net::SSH.start(self.address, self.user, password: self.password, port: self.port, timeout: 5, number_of_password_prompts: 0)
      else
        raise "No authentication method for server #{self.id}"
      end
    rescue => e
      @ssh = e
    end
    return @ssh
  end

  def ssh_string
    return "ssh #{self.user}@#{self.address}#{" -p " + self.port.to_s unless self.port == 22}"
  end

  def self.parse_screens(input) #For use later, parse the return of 'screen -ls' to see what servers are running
    @return = []
    regex   = Regexp.new(".*?\\d+.*?(\\d+)", Regexp::IGNORECASE)
    input.split("\n").each do |line|
      if line.include?("serverbot")
        @return << regex.match(line)[1].to_i if regex.match(line)
      end
    end
    return @return
  end

  def git_update
    p self.id, self.ssh.exec!("cd #{File.join(self.working_path, 'configs')}; git pull")
  end
end
