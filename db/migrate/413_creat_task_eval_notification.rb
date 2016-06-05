require Rails.root.join("db","migrate","migration_helper.rb")

class CreatTaskEvalNotification < ActiveRecord::Migration
  include MigrationHelper

  def change
    create_table :task_eval_notifications, id: :uuid do |t|
      t.uuid :task_id, null: false, index: true
      t.string :state
    end

    add_auto_timestamps 'task_eval_notifications'

    add_foreign_key :task_eval_notifications, :tasks, on_delete: :cascade


    ### create task_eval_notification on task create ###########################

    reversible do |dir|
      dir.up do

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION
            create_task_eval_notification_on_task_create()
          RETURNS TRIGGER AS $$
          BEGIN
            INSERT INTO task_eval_notifications
              (task_id, state) VALUES (NEW.id, NEW.state);
            RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL

        execute <<-SQL.strip_heredoc
          CREATE TRIGGER create_task_eval_notification_on_task_create
          AFTER INSERT ON tasks FOR EACH ROW
          EXECUTE PROCEDURE
            create_task_eval_notification_on_task_create();
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER
            create_task_eval_notification_on_task_create ON tasks;
        SQL
      end
    end


    ### create task_eval_notification on task update ###########################

    reversible do |dir|
      dir.up do

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION
            update_task_eval_notification_on_task_update()
          RETURNS TRIGGER AS $$
          BEGIN
            INSERT INTO task_eval_notifications
              (task_id, state) VALUES (NEW.id, NEW.state);
            RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL

        execute <<-SQL.strip_heredoc
          CREATE TRIGGER
            update_task_eval_notification_on_task_update
          AFTER UPDATE ON tasks FOR EACH ROW
          WHEN (OLD.state IS DISTINCT FROM NEW.state)
          EXECUTE PROCEDURE
            update_task_eval_notification_on_task_update();
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER
            update_task_eval_notification_on_task_update ON tasks;
        SQL
      end

    end
  end
end
