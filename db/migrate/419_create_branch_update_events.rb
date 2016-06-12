require Rails.root.join("db","migrate","migration_helper.rb")

class CreateBranchUpdateEvents < ActiveRecord::Migration
  include MigrationHelper

  def change
    create_table :branch_update_events, id: :uuid do |t|
      t.uuid :branch_id, null: false
      t.string :tree_id, limit: 40, null: false
    end
    add_foreign_key :branch_update_events, :branches, on_delete: :cascade
    add_auto_timestamps :branch_update_events, updated_at: false
    add_index :branch_update_events, :created_at

    reversible do |dir|
      dir.up do

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION
            create_branch_update_event()
          RETURNS TRIGGER AS $$
          DECLARE
          tree_id TEXT;
          BEGIN
             SELECT commits.tree_id INTO tree_id
                FROM commits
                WHERE id = NEW.current_commit_id;
             INSERT INTO branch_update_events
              (tree_id, branch_id)
              VALUES (tree_id, NEW.id);
             RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL

        execute <<-SQL.strip_heredoc
          CREATE TRIGGER
            create_branch_update_event
          AFTER UPDATE OR INSERT ON branches FOR EACH ROW
          EXECUTE PROCEDURE
            create_branch_update_event();
        SQL

      end

      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER create_branch_update_event ON branches;
          DROP FUNCTION create_branch_update_event();
        SQL
      end

    end

    ### clean old events ######################################################

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION clean_branch_update_events()
          RETURNS trigger AS $$
          BEGIN
            DELETE FROM branch_update_events
              WHERE created_at < NOW() - INTERVAL '3 days';
            RETURN NULL;
          END;
          $$ language 'plpgsql';
        SQL

        execute <<-SQL.strip_heredoc
          CREATE TRIGGER clean_branch_update_events
          AFTER INSERT ON branch_update_events FOR EACH STATEMENT
          EXECUTE PROCEDURE clean_branch_update_events();
        SQL
      end

      dir.down do
        execute <<-SQL.strip_heredoc
            DROP TRIGGER clean_branch_update_events ON branch_update_events;
            DROP FUNCTION clean_branch_update_events();
        SQL
      end
    end




  end
end
