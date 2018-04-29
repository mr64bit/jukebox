class AddKeyPathToHostMachine < ActiveRecord::Migration
  def change
    add_column :host_machines, :key_path, :string
  end
end
