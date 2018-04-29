class AddServerImageIdToServers < ActiveRecord::Migration
  def change
    add_column :servers, :server_image_id, :integer
  end
end
