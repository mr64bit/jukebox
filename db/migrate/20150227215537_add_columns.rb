class AddColumns < ActiveRecord::Migration
  def change
    add_column :servers, :state, :string
    add_column :servers, :map, :string
    add_column :servers, :num_players, :integer
    remove_column :servers, :server_path

    remove_column :host_machines, :management_user
    remove_column :host_machines, :management_user_password
    remove_column :host_machines, :gameserver_user
    remove_column :host_machines, :gameserver_user_password
    remove_column :host_machines, :unix_group
    remove_column :host_machines, :steamcmd_path
    remove_column :host_machines, :active
    remove_column :host_machines, :steamcmd_exists
    add_column :host_machines, :state, :string

    remove_column :server_images, :download_install
    add_column :server_images, :config_source, :string
  end
end
