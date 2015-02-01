class AddExclusiveResourcesToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :exclusive_resources, :string, array: true, null: false, default: '{}'
    add_index :tasks, :exclusive_resources
  end
end
