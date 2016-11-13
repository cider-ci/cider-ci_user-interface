require Rails.root.join("db","migrate","migration_helper.rb")

class ImproveEvents < ActiveRecord::Migration
  include MigrationHelper
  def change
    remove_column :repositories, :remote_http_fetch_token, :text
    add_events_table "repositories"
    add_events_table "users"
  end
end
