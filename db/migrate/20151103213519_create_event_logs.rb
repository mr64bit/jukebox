class CreateEventLogs < ActiveRecord::Migration
  def change
    create_table :event_logs do |t|
      t.string :event_type
      t.integer :winning_team_id
      t.integer :losing_team_id
      t.integer :winning_team_score
      t.integer :losing_team_score
      t.boolean :acknowledged, default: false
      t.integer :user_id
      t.integer :match_id
      t.integer :match_map_id
      t.integer :server_id

      t.timestamps null: false
    end
  end
end
