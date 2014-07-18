class DropAttachments < ActiveRecord::Migration
  def up 
    drop_table :attachments 
    remove_column :timeout_settings, :attachment_retention_time_hours
  end
end
