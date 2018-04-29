class AddStateToServerImages < ActiveRecord::Migration
  def change
    add_column :server_images, :state, :string
  end
end
