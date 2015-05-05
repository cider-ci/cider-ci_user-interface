require Rails.root.join("db","migrate","migration_helper.rb")
class CreateAttachments < ActiveRecord::Migration
  include MigrationHelper
  def change

    %w(tree trial).each do |item| 

      table_name= "#{item}_attachments"
      create_table table_name, id: :uuid do |t|
        t.text :path, null: false
        t.text :content_length
        t.text :content_type
        t.timestamp :to_be_retained_before
        t.index [:path], unique: true
      end

      add_auto_timestamps table_name

    end
  end
end
