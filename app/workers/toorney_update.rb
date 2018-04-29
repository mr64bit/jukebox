class ToorneyUpdate
  include Sidekiq::Worker
  def perform
    tournament = Tournament.find(Settings::CURRENT_TOURNAMENT)
    tournament.update_teams
    tournament.poll_matches
  end
end
