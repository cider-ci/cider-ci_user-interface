class AdjustExecutions < ActiveRecord::Migration
  def change
    add_column :executions, :description, :text
    change_column :executions, :priority, :integer, default: 0
    change_column :tasks, :priority, :integer, default: 0
  end
end
