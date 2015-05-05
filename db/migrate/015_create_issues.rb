require Rails.root.join("db","migrate","migration_helper.rb")
class CreateIssues < ActiveRecord::Migration
  include MigrationHelper
  def change
    %w(job trial).each do |item|

      table_name= "#{item}_issues"

      create_table table_name , id: :uuid do |t|
        t.text :title
        t.text :description
        t.string :type, null: false, default: 'error'
        t.uuid "#{item}_id", null: false
        t.index "#{item}_id"
      end

      add_auto_timestamps table_name

      add_foreign_key table_name, item.pluralize, 
        name: "#{table_name}_#{item.pluralize}_fkey", 
        on_delete: :cascade

    end
  end
end
