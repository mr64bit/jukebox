class AddMetricToServer < ActiveRecord::Migration
  def change
    add_column :servers, :metric, :integer, default: 100
  end
end
