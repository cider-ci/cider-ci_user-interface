require Rails.root.join("db","migrate","migration_helper.rb")
require 'active_record/connection_adapters/abstract/schema_definitions'

class CreateSubmodules < ActiveRecord::Migration
  def change
    create_table :submodules, id: false do |t|
      t.string :submodule_commit_id, length: 40, null: false
      t.text :path, null: false
      t.string :commit_id, length: 40, null: false
      t.index :commit_id
    end

    add_foreign_key :submodules, :commits, on_delete: :cascade

    reversible do |dir|
      dir.up do 
        execute 'ALTER TABLE submodules ADD PRIMARY KEY (commit_id ,path);'
      end
    end

  end

end
