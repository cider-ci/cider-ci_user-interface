class AddTaskErrors < ActiveRecord::Migration
  def change
    add_column :tasks, :entity_errors, :jsonb, default: '[]'
    remove_column :tasks, :error, :string
  end
end
