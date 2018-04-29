class CreateMatches < ActiveRecord::Migration
  def change
    create_table :matches do |t|
      t.string :state
      t.string :match_code
      t.datetime :starts_at
      t.string :map
      t.string :type
      t.string :state
      t.string :region
      t.string :score

      t.timestamps null: false
    end
  end
end
