RailsAdmin.config do |config|

  config.main_app_name = 'Jukebox'

  config.authorize_with do
    authenticate_or_request_with_http_basic('Admin login') do |user, password|
      bcrypt = BCrypt::Password.new("$2a$10$w1DcfqULII0ay2t4Dbj3VecHq2pdgtnsEdEbxh3L0sqJexRX6RDhe")
      user == 'evlbr-staff' && bcrypt == password
    end
  end

  ### Popular gems integration

  ## == Devise ==
  # config.authenticate_with do
  #   warden.authenticate! scope: :user
  # end
  # config.current_user_method(&:current_user)

  ## == Cancan ==
  # config.authorize_with :cancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit do except %w(Server EventLog) end
    show_in_app
    toggle
    state

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.included_models = %w(Match MatchMap Team Player EventLog Server)
  config.navigation_static_links = { 'Public View' => '/matches' }
end
