class EventLog < ActiveRecord::Base
  belongs_to :server
  belongs_to :match
  belongs_to :match_map
  belongs_to :winning_team, class_name: 'Team'
  belongs_to :losing_team, class_name: 'Team'

  rails_admin do
    list do
      field :id
      field :event_type do label 'Type' end
      field :match
      field :match_map_id do
        label 'Map'
        formatted_value do
          begin
            bindings[:object].match_map.map
          rescue
            ''
          end
        end
      end
      field :match_id do
        label 'Score'
        formatted_value do
          event = bindings[:object]
          begin
            "#{event.winning_team.tag} #{event.winning_team_score}-#{event.losing_team_score} #{event.losing_team.tag}"
          rescue
            ''
          end
        end
      end
      field :acknowledged, :toggle
    end
  end

  def self.event_types
    %w(server_ready map_start map_end map_score)
  end

  def self.new_event(type, model)
    raise "#{type} is not a known event type!" unless event_types.include?(type)
    event = self.new(event_type: type)
    case model.class.to_s
      when 'Match'
        event.match = model
        event.match_map = model.current_map
        event.server = Server.unscoped.find_by(match_id: model.id) #just calling model.server will query for the host data which we don't need.

      when 'MatchMap'
        event.match = model.match
        event.match_map = model
        event.server = Server.unscoped.find_by(match_id: model.match_id)

    end
    case type
      when 'map_start', 'map_score', 'map_end'
        event.winning_team = model.current_winner_team
        event.winning_team_score = model.current_winner_score
        event.losing_team = model.current_loser_team
        event.losing_team_score = model.current_loser_score
    end
    event.save
  end
end
