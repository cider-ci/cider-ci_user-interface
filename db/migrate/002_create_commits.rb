require Rails.root.join("db","migrate","migration_helper.rb")
require 'active_record/connection_adapters/abstract/schema_definitions'


class CreateCommits < ActiveRecord::Migration
  include MigrationHelper

  def change

    create_table :commits, id: :string, limit: 40 do |t|

      t.string :tree_id, limit: 40
      t.index :tree_id

      t.integer :depth

      t.string :author_name
      t.string :author_email
      t.timestamp :author_date
      t.index :author_date

      t.string :committer_name
      t.string :committer_email
      t.timestamp :committer_date
      t.index :committer_date

      t.text :subject
      t.text :body

    end

    add_auto_timestamps :commits

    add_index :commits, :updated_at

    create_text_index :commits, :body
    create_text_index :commits, :author_name
    create_text_index :commits, :author_email
    create_text_index :commits, :committer_name
    create_text_index :commits, :committer_email
    create_text_index :commits, :subject
    create_text_index :commits, :body


    create_table :commit_arcs, id: false do |t|
      t.string :parent_id, limit: 40, null: false
      t.string :child_id, limit: 40, null: false
    end
    add_index :commit_arcs, [:parent_id,:child_id], unique: true
    add_index :commit_arcs, [:child_id,:parent_id]
    add_foreign_key :commit_arcs, :commits, column: :parent_id, on_delete: :cascade
    add_foreign_key :commit_arcs, :commits, column: :child_id, on_delete: :cascade


  end

end
