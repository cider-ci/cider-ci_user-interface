require Rails.root.join("db","migrate","migration_helper.rb")

class CreateTreeIdNotifications < ActiveRecord::Migration
  include MigrationHelper

  def change
    create_table :tree_id_notifications, id: :uuid do |t|
      t.string :tree_id, limit: 40, null: false
      t.uuid :branch_id
      t.uuid :job_id
      t.text :description
    end

    add_auto_timestamps 'tree_id_notifications'


    ### create tree_id_notification on branch update ###########################

    reversible do |dir|
      dir.up do

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION
            create_tree_id_notification_on_branch_change()
          RETURNS TRIGGER AS $$
          DECLARE
          tree_id TEXT;
          BEGIN
             SELECT commits.tree_id INTO tree_id
                FROM commits
                WHERE id = NEW.current_commit_id;
             INSERT INTO tree_id_notifications
              (tree_id, branch_id,description)
              VALUES (tree_id, NEW.id,TG_OP);
             RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL

        execute <<-SQL.strip_heredoc
          CREATE TRIGGER
            create_tree_id_notification_on_branch_change
          AFTER UPDATE OR INSERT ON branches FOR EACH ROW
          EXECUTE PROCEDURE
            create_tree_id_notification_on_branch_change();
        SQL

      end

      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER
            create_tree_id_notification_on_branch_change ON branches;
        SQL
      end

    end


    ### create tree_id_notification on job update ##############################

    reversible do |dir|
      dir.up do

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION
            create_tree_id_notification_on_job_state_change()
          RETURNS TRIGGER AS $$
          BEGIN
            INSERT INTO tree_id_notifications
              (tree_id, job_id,description)
              VALUES (NEW.tree_id, NEW.id, NEW.state);

            INSERT INTO tree_id_notifications
              (tree_id, job_id, description)
            SELECT DISTINCT
              supermodule_commits.tree_id, NEW.id, NEW.state
            FROM commits AS submodule_commits
            INNER JOIN submodules
              ON submodule_commit_id = submodule_commits.id
            INNER JOIN commits AS supermodule_commits
              ON submodules.commit_id = supermodule_commits.id
            WHERE submodule_commits.tree_id = NEW.tree_id;

            RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL

        execute <<-SQL.strip_heredoc
          CREATE TRIGGER
            create_tree_id_notification_on_job_state_change
          AFTER UPDATE ON jobs FOR EACH ROW
          WHEN (OLD.state IS DISTINCT FROM NEW.state)
          EXECUTE PROCEDURE
            create_tree_id_notification_on_job_state_change();
        SQL

      end

      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER
            create_tree_id_notification_on_job_state_change
            ON jobs;
        SQL
      end
    end

  end

end
