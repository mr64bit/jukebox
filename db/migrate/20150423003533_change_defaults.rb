class ChangeDefaults < ActiveRecord::Migration
  def change
    change_column_default :matches, :match_type, "single"
    change_column_default :server_images, :path, "tf2/"
    change_column_default :server_images, :config_source, "tf2"
    change_column_default :servers, :managed, true
    change_column_default :servers, :num_players, 0
  end
end
