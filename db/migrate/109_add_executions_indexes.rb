class AddExecutionsIndexes < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do 
        execute "CREATE INDEX exectutions_lower_name_idx ON executions(lower(name))"
        execute "CREATE UNIQUE INDEX exectutions_tree_id_lower_name_idx ON executions(tree_id,lower(name))"
      end
      dir.down do
        execute "DROP INDEX exectutions_tree_id_lower_name_idx"
        execute "DROP INDEX exectutions_lower_name_idx"
      end
    end

  end
end
