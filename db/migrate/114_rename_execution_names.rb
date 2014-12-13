class RenameExecutionNames < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute "CREATE INDEX branches_lower_name_idx ON branches(lower(name))"
        execute "CREATE INDEX repositories_lower_name_idx ON repositories(lower(name))"
        execute "ALTER TABLE executions DISABLE TRIGGER update_updated_at_column_of_executions;
          UPDATE executions SET name = 'Tests' WHERE name ilike 'test';
          ALTER TABLE executions ENABLE TRIGGER update_updated_at_column_of_executions;"
      end
      dir.down do
        execute "DROP INDEX  branches_lower_name_idx;"
        execute "DROP INDEX  repositories_lower_name_idx;"
      end
    end
  end
end
