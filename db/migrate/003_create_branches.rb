require Rails.root.join("db","migrate","migration_helper.rb")
require 'active_record/connection_adapters/abstract/schema_definitions'

class CreateBranches < ActiveRecord::Migration
  include MigrationHelper
  def change

    create_table :branches, id: :uuid do |t|
      t.uuid :repository_id, null: false
      t.string :name, null: false
      t.string :current_commit_id, limit: 40, null: false
    end

    add_foreign_key :branches, :repositories
    add_foreign_key :branches, :commits, column: :current_commit_id, on_delete: :cascade
    add_index :branches, :name
    add_index :branches, [:repository_id,:name], unique: true

    add_auto_timestamps :branches


    reversible do |dir|
      dir.up do 
        execute "CREATE INDEX branches_lower_name_idx ON branches(lower(name))"
      end
    end

  end
end
