class ChangeLogstfIdFieldTypeToString < ActiveRecord::Migration
  def up
    rename_column :matches, :logstf_id, :logstf_bk
    add_column :matches, :logstf_id, :string
  end
  def down
    remove_column :matches, :logstf_id
    rename_column :matches, :logstf_bk, :logstf_id
  end
end
