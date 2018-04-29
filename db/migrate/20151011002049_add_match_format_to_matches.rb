class AddMatchFormatToMatches < ActiveRecord::Migration
  def change
    add_column :matches, :match_format_name, :string
  end
end
