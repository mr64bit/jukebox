class ServerImage < ActiveRecord::Base
  include AASM
  belongs_to :host_machine
  has_many :servers

  aasm column: "state" do
    state :nonexistent, initial: true
    state :installing
    state :updating
    state :installed

    event :install_image do
      transitions from: :nonexistent, to: :installing
      after do
        CreateServerImage.perform_in(1.second, self.id)
      end
    end
    event :update_image do
      transitions from: :installed, to: :updating, guard: :all_stopped?
      after do
        UpdateImage.perform_in(1.second, self.id)
      end
    end
    event :image_ready do
      transitions from: [:installing, :updating], to: :installed
    end
  end

  def all_stopped? #Check if all this image's servers are stopped.
    self.servers.all? { |server| ['stopped', 'nonexistent'].include? server.state}
  end

end
