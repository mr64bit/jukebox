class AddBetterDefaults < ActiveRecord::Migration
  def change
    change_column_default :host_machines, :address, "localhost"
    change_column_default :host_machines, :working_path, "/home/steam/"
    change_column_default :host_machines, :user, "steam"
    change_column_default :host_machines, :password, "5t3am"
    change_column_default :host_machines, :region, "dal"

    change_column_default :match_maps, :part_of_set, 0

    change_column_default :matches, :region, "dal"
    change_column_default :matches, :match_format_name, "evl_ultiduo"

    change_column_default :servers, :listen_port, 27015
    change_column_default :servers, :game_port, 27005
    change_column_default :servers, :stv_port, 27020
    change_column_default :servers, :rcon_password, "fuckyoubic"
    change_column_default :servers, :sv_password, "joinme"
    change_column_default :servers, :region, "dal"
  end
end
