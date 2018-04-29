class ChangePlayerSteamIdFromStringToLong < ActiveRecord::Migration
  def change
    remove_column(:players, :steam_id, :string)
    add_column(:players, :steam_id, :bigint)
  end
end
