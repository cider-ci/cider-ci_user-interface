require Rails.root.join("db","migrate","migration_helper.rb")

class CreatePendingJobEvaluations < ActiveRecord::Migration
  include MigrationHelper

  def change
    create_table :pending_job_evaluations, uuid: true do |t|
      t.uuid :job_id, null: false
      t.uuid :task_state_update_event_id
    end
    add_auto_timestamps :pending_job_evaluations, updated_at: false
    add_index :pending_job_evaluations, :created_at
    add_foreign_key :pending_job_evaluations, :jobs, on_delete: :cascade
    add_foreign_key :pending_job_evaluations, :task_state_update_events, on_delete: :cascade

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION
            create_pending_job_evaluation_on_task_state_update_event_insert()
          RETURNS TRIGGER AS $$
          DECLARE
            t_id UUID;
          BEGIN
             SELECT job_id INTO t_id
                FROM tasks
                WHERE tasks.id = NEW.task_id;
             INSERT INTO pending_job_evaluations
              (job_id, task_state_update_event_id) VALUES (t_id, NEW.id);
             RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL
        execute <<-SQL.strip_heredoc
          CREATE TRIGGER
            create_pending_job_evaluation_on_task_state_update_event_insert
          AFTER INSERT ON task_state_update_events FOR EACH ROW
          EXECUTE PROCEDURE
            create_pending_job_evaluation_on_task_state_update_event_insert();
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER
            create_pending_job_evaluation_on_task_state_update_event_insert
            ON task_state_update_events ;
          DROP FUNCTION
            create_pending_job_evaluation_on_task_state_update_event_insert();
        SQL
      end
    end

  end
end
