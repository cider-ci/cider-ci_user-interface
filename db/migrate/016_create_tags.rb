require Rails.root.join("db","migrate","migration_helper.rb")
class CreateTags < ActiveRecord::Migration
  include MigrationHelper

  def change

    create_table :tags, id: :uuid do |t|
      t.string :tag
      t.index :tag
    end
    create_trgm_index :tags, :tag
    create_text_index :tags, :tag
    add_auto_timestamps :tags

    create_table :jobs_tags, id: false do |t|
      t.uuid :job_id
      t.uuid :tag_id
    end
    add_index :jobs_tags,[:job_id,:tag_id], unique: true
    add_index :jobs_tags,[:tag_id,:job_id]

    add_foreign_key :jobs_tags, :jobs, name: "jobs-tags_jobs_fkey", on_delete: :cascade
    add_foreign_key :jobs_tags, :tags, name: "jobs-tags_tags_fkey", on_delete: :cascade

  end

end
