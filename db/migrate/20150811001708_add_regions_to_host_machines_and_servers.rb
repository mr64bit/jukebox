class AddRegionsToHostMachinesAndServers < ActiveRecord::Migration
  def change
    add_column :host_machines, :region, :string
    add_column :servers, :region, :string
  end
end
