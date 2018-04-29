class CreateHostMachines < ActiveRecord::Migration
  def change
    create_table :host_machines do |t|
      t.string :address
      t.integer :port, default: '22'
      t.string :management_user
      t.string :management_user_password
      t.string :gameserver_user
      t.string :gameserver_user_password
      t.string :unix_group
      t.string :working_path
      t.string :steamcmd_path, default: 'steamcmd/'
      t.boolean :active, default: false
      t.boolean :steamcmd_exists, default: false

      t.timestamps null: false
    end
  end
end
