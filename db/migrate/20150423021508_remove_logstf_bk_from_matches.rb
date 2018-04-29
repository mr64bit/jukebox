class RemoveLogstfBkFromMatches < ActiveRecord::Migration
  def up
    remove_column :matches, :logstf_bk
  end
end
