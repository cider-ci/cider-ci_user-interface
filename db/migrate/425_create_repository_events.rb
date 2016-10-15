require Rails.root.join("db","migrate","migration_helper.rb")

class CreateRepositoryEvents < ActiveRecord::Migration
  include MigrationHelper

  def change

    add_events_table "repositories"
    add_events_table "users"

  end
end
