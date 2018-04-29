class MatchDecorator < Draper::Decorator
  delegate_all

  def short_scores_logs
    model.match_maps.sort_by{|map| map.part_of_set}.map do |map|
      logs = map.logs.map.with_index(1){|log,i| h.link_to(i, "http://logs.tf/#{log['id']}")}
      "#{map.short_scores} #{!logs.empty? ? "(logs: #{logs.join(', ')})" : ''}"
    end
  end
end
