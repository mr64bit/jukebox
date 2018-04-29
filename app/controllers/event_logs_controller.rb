class EventLogsController < ApplicationController
  before_filter :allow_cors

  def index
    @events = (EventLog.includes(:match, :match_map, :winning_team, :losing_team).order('created_at desc').first(10) +
               EventLog.includes(:match, :match_map, :winning_team, :losing_team).where(created_at: 10.minutes.ago..Time.now)).uniq.sort_by{|a| a.created_at}.reverse
  end

  private

  def allow_cors
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
 end
end
