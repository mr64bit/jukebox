class CreateMatchMaps < ActiveRecord::Migration
  def change
    create_table :match_maps do |t|
      t.belongs_to :match
      t.string :map
      t.string :logs
      t.string :score
      t.integer :part_of_set
      t.string :state
      t.timestamps null: false
    end
  end
end
