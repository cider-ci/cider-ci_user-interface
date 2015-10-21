class RemoveTags < ActiveRecord::Migration
  def change
    drop_table :jobs_tags
    drop_table :tags
  end
end
