class ResurectExecutionTreeIdSpecIdUniqueness < ActiveRecord::Migration
  def change
    remove_index :executions, column: [:tree_id,:specification_id]
    add_index :executions, [:tree_id,:specification_id], unique: true,
      name: 'index_executions_on_column_and_tree_id_and_specification_id'
  end
end
