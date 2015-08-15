class RemoveTimeoutSettings < ActiveRecord::Migration
  def change
    drop_table :timeout_settings
    add_index :repositories, :created_at
    add_index :repositories, :updated_at
  end
end
