require Rails.root.join("db","migrate","migration_helper.rb")

class CreateRepositories < ActiveRecord::Migration
  include MigrationHelper

  def change

    create_table :repositories, id: :uuid do |t|
      t.text :origin_uri
      t.string :name 
      t.integer :git_fetch_and_update_interval, default: 60
      t.integer :git_update_interval 
      t.boolean :public_view_permission, default: false
    end
    add_auto_timestamps :repositories


  end
end
