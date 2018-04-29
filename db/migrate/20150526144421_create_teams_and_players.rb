class CreateTeamsAndPlayers < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name
      t.string :tag
      t.timestamps null: false
    end
    create_table :players do |t|
      t.string :name
      t.integer :steam_id, limit: 8
      t.string :addresses
      t.belongs_to :team
      t.timestamps null: false
    end
    create_table :matches_teams, id: false do |t|
      t.belongs_to :team, index: true
      t.belongs_to :match, index: true
    end
  end
end
