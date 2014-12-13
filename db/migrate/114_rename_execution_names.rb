class RenameExecutionNames < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute "CREATE INDEX branches_lower_name_idx ON branches(lower(name))"
        execute "CREATE INDEX repositories_lower_name_idx ON repositories(lower(name))"
        execute " SET session_replication_role = REPLICA; 
          UPDATE executions SET name = 'Tests' WHERE name ilike 'test';
          SET session_replication_role = DEFAULT;"
      end
      dir.down do
        execute "DROP INDEX  branches_lower_name_idx;"
        execute "DROP INDEX  repositories_lower_name_idx;"
      end
    end
  end
end
