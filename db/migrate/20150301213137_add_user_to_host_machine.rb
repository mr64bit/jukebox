class AddUserToHostMachine < ActiveRecord::Migration
  def change
    add_column :host_machines, :user, :string
    add_column :host_machines, :password, :string
  end
end
