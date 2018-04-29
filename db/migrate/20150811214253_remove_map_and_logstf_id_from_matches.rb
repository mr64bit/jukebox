class RemoveMapAndLogstfIdFromMatches < ActiveRecord::Migration
  def change
	remove_column :matches, :logstf_id
	remove_column :matches, :map
  end
end
