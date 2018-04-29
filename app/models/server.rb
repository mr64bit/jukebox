class Server < ActiveRecord::Base
  include AASM
  belongs_to :server_image
  belongs_to :match
  has_paper_trail only: :state

  aasm column: "state" do
    state :nonexistent, initial: true
    state :creating
    state :stopped
    state :starting
    state :stopping
    state :running
    state :mapchange
    state :not_responding

    event :create_server, guards: :is_managed? do
      transitions from: :nonexistent, to: :creating
      after do
        CreateServer.perform_in(2.seconds, self.id)
      end
    end
    event :server_created, guards: :is_managed? do
      transitions from: :creating, to: :stopped
    end
    event :server_start, guards: :is_managed? do
      transitions from: :stopped, to: :starting
      after do
        self.start_server
      end
    end
    event :server_stop, guards: :is_managed? do
      transitions to: :stopping
      after do
        self.rcon.rcon_exec('quit')
        self.update(num_players: 0)
      end
    end
    event :changed_map do
      transitions from: :running, to: :mapchange
    end
  end

  rails_admin do
    list do
      field :id
      field :state
      field :match
      field :listen_port do
        label 'Connect'
        formatted_value do bindings[:view].link_to(bindings[:object].connect_string, "steam://connect/#{bindings[:object].real_address}:#{bindings[:object].listen_port}/#{bindings[:object].sv_password}") end
      end
      field :stv_port do
        label 'STV'
        formatted_value do bindings[:view].link_to(bindings[:object].stv_string, "steam://connect/#{bindings[:object].real_address}:#{bindings[:object].stv_port}") end
      end
      field :num_players
    end
    show do
      field :id
      field :state
      field :match
      field :listen_port do
        label 'Connect'
        formatted_value do bindings[:view].link_to(bindings[:object].connect_string, "steam://connect/#{bindings[:object].real_address}:#{bindings[:object].listen_port}/#{bindings[:object].sv_password}") end
      end
      field :stv_port do
        label 'STV'
        formatted_value do bindings[:view].link_to(bindings[:object].stv_string, "steam://connect/#{bindings[:object].real_address}:#{bindings[:object].stv_port}") end
      end
      field :num_players
      field :map
      field :region
    end
  end

  default_scope { includes(server_image: :host_machine) }
  scope :available, -> { where('match_id IS NULL AND metric != 0 AND ((managed = ? AND state = ?) OR (managed = ? AND state = ?))', false, 'running', true, 'stopped').reorder('metric ASC') }

  after_create :calculate_ports, if: :managed
  after_create :generate_passwords, if: :managed
  before_create :inherit_from_host, if: :managed

  def rcon() #returns an rcon object connected to the server it was called from
    begin
      @rcon = SteamCondenser::Servers::SourceServer.new(self.real_address, port = self.listen_port)
      @rcon.rcon_auth(self.rcon_password)
    rescue Exception => e
      @rcon = e
    end
    return @rcon
  end

  def real_address
    if self.managed
      return self.server_image.host_machine.address
    else
      return self.address
    end
  end

  def force_quit()
    raise "Can't quit un-managed server" unless self.managed
    @ssh = self.server_image.host_machine.ssh
    result =  @ssh.exec!("screen -S serverbot-#{self.id} -X quit")
    self.update(state: 'stopped')
    if result == nil
      return true
    elsif result
      Rails.logger.warn "Server #{self.id} not found running."
    end
  end

  def server_check
    #TODO: Set server as not responding after n failures
    debug = false
    @rcon = self.rcon
    # Rails.logger.debug "Server id: #{self.id}, state: #{self.state}, rcon: #{@rcon.class}"
    case
      when (['stopped', 'stopping'].include? self.state) #if the server state is stopped or stopping, ignore it
        Rails.logger.debug "ignoring server #{self.id}" if debug

      when (['starting', 'mapchange'].include? self.state) && (rcon.class == SteamCondenser::Error::Timeout) #if the server state is starting or mapchange, and if it's not up yet
        Rails.logger.info "Server #{self.id} is not ready yet" if debug

      when (['starting', 'mapchange'].include? self.state) && (rcon.class == SteamCondenser::Servers::SourceServer) && (rcon.rcon_authenticated?) #if the server state is starting or mapchange, and if it is up, and if we successfully authenticated over rcon
        self.state = "running"
        Rails.logger.info "Server #{self.id} is running" if debug

      when (['running'].include? self.state) && (rcon.class == SteamCondenser::Servers::SourceServer) #all is well...
        self.num_players = @rcon.server_info[:number_of_players]
        unless self.match_id #if not being used for a match, update info
          self.map = @rcon.server_info[:map_name] unless self.match_id
          self.hostname = @rcon.server_info[:server_name]
        end

      when (self.state == 'running') && ([Errno::ECONNREFUSED, SteamCondenser::Error::Timeout].include? rcon.class) #should be running but we can't reach it
        self.state = 'not_responding'
        Rails.logger.info "Server #{self.id} is not responding" if debug

      when (self.state == 'not_responding') && (rcon.class == SteamCondenser::Servers::SourceServer) #Server recovered!
        self.state = 'running'
        Rails.logger.info "Server #{self.id} recovered!" if debug

      else
    end
    self.save if changed?
  end

  def start_server
    ssh = self.server_image.host_machine.ssh
    raise "rcon_password on #{self.id} cannot be nil" unless self.rcon_password

    p ssh.exec!("screen -dmS serverbot-#{self.id} #{File.join(self.server_image.host_machine.working_path, 'images', self.server_image.path, 'srcds_run')} -game #{self.server_image.game} +maxplayers 24 +map #{self.map} +sm_basepath sourcemod/sm-#{self.id} +rcon_password '#{self.rcon_password}' +sv_password '#{self.sv_password}' +hostname \"#{self.hostname}\" +hostport #{self.listen_port} +tv_port #{self.stv_port} +clientport #{self.game_port} -ip #{self.real_address} +sv_rcon_whitelist_address 45.34.11.153 +evl_server_id #{self.id} +evl_api_password WFsxvBDyiO2ec9-K93NBQQ")
    #Will turn into something like "screen -dmS serverbot-23 /var/serverbot/images/tf2/srcds_run -game tf +maxplayers 24 +map cp_process_final +sm_basepath sourcemod/sm-23 +rcon_password 'rcon' +sv_password 'join' +hostmane 'serverbot test' +hostport 27069 +tv_port 27070 +clientport 27071 -ip 0.0.0.0"
    ssh.close
  end

  def change_map(map)
    @rcon = self.rcon
    raise "Map '#{map}' not found." unless @rcon.rcon_exec("maps #{map}").split("\n").find {|string| string.ends_with?(map)}
    raise "Some other error" unless @rcon.rcon_exec("changelevel #{map}") == ''
    self.changed_map!
    self.update(map: map)
  end

  def exec_cfg(config)
    begin
      @rcon = self.rcon
      raise "Bad config '#{config}'" if @rcon.rcon_exec("exec #{config}") == "'#{config}' not present; not executing."
    rescue SteamCondenser::Error::Timeout #because the server always lags out for several seconds after
    end
  end

  def self.find_cfg(matchmap)
    match = matchmap.match
    prefix = match.match_format.exec_prefix || match.match_format.name
    suffix = matchmap.map_rules.exec_suffix || matchmap.map_rules.name
    return "#{prefix}_#{suffix}"
  end

  def connect_string
    return "connect #{self.real_address}:#{self.listen_port}; password #{self.sv_password}"
  end

  def stv_string
    return "connect #{self.real_address}:#{self.stv_port}"
  end

  def generate_passwords(do_join = false, do_rcon = false)
    if self.sv_password == nil || do_join.class
      self.sv_password = SecureRandom.hex(3)
      #self.sv_password = 'evlbr' #we're using the same password for all servers, using the whitelist for protection
    end
    if (self.rcon_password == nil || do_rcon.class) && (self.managed == true && (['stopped', 'nonexistent'].include? self.state))
      self.rcon_password = SecureRandom.hex(8)
    end
    self.rcon.rcon_exec("sv_password #{self.sv_password}") if self.running?
    self.save! if changed?
  end

  def clear_server
    return if %w(stopped stopping).include?(self.state)
    self.prettychat("Server shutting down")
    if self.managed
      self.server_stop!
    else
      self.rcon.rcon_exec("whitelist_filename whitelist.txt; sm_whitelist_reload")
      self.rcon.rcon_exec("kickall")
      self.rcon.rcon_exec("logaddress_delall") #if we were using livestate for this match, stop sending to it.
    end
  end

  def prettychat(message)
    Rails.logger.info message
    self.rcon.rcon_exec("evl_prettychat #{message}")
  end

  def live_stats_setup
    curl = Curl::Easy.http_post("http://scripts.evlbr.com:3001/matches/",
                                Curl::PostField.content('match[host]', "#{self.real_address}:#{self.listen_port}"),
                                Curl::PostField.content('match[rcon]', self.rcon_password))
    curl.http_auth_types = :basic
    curl.username = 'live'
    curl.password = 'evlonly'
    curl.perform

    return Regexp.new(".*?\\d+.*?(\\d+)",Regexp::IGNORECASE).match(curl.body_str)[1]
  end

  private

  def calculate_ports
    @base            = 27000 + (self.id * 3)
    self.listen_port ||= @base
    self.stv_port    ||= @base + 1
    self.game_port   ||= @base + 2
    self.save!
  end

  def inherit_from_host
    self.region = self.server_image.host_machine.region if server_image.host_machine.region
  end

  def is_managed?
    self.managed
  end
end
