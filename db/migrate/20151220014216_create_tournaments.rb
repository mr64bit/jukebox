class CreateTournaments < ActiveRecord::Migration
  def change
    create_table(:tournaments, id: false) do |t|
      t.string :id, null: false

      t.timestamps null: false
    end

    add_index :tournaments, :id, unique: true
    add_column :matches, :tournament_id, :string
    add_column :matches, :toorney_id, :string
    add_column :teams, :tournament_id, :string
    add_column :teams, :toorney_id, :string
  end
end
