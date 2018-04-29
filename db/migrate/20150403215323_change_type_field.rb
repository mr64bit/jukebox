class ChangeTypeField < ActiveRecord::Migration
  def change
    rename_column :matches, "type", :match_type
    add_column :matches, :logstf_id, :integer
  end
end
