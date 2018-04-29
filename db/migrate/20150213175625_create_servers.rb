class CreateServers < ActiveRecord::Migration
  def change
    create_table :servers do |t|
      t.belongs_to :match

      t.string :hostname
      t.string :address
      t.integer :listen_port
      t.integer :game_port
      t.integer :stv_port
      t.string :rcon_password
      t.string :sv_password
      t.boolean :managed, default: false
      t.string :server_path

      t.timestamps null: false
    end
  end
end
