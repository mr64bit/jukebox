class CreateServerImages < ActiveRecord::Migration
  def change
    create_table :server_images do |t|
      t.string :game, default: 'tf'
      t.integer :appid, default: 232250
      t.string :path, default: 'servers/'
      t.string :download_install
      t.belongs_to :host_machine


      t.timestamps null: false
    end
  end
end
