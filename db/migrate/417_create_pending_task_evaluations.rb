require Rails.root.join("db","migrate","migration_helper.rb")

class CreatePendingTaskEvaluations < ActiveRecord::Migration
  include MigrationHelper

  def change
    create_table :pending_task_evaluations, id: :uuid do |t|
      t.uuid :task_id, null: false
      t.uuid :trial_state_update_event_id
    end
    add_auto_timestamps :pending_task_evaluations, updated_at: false
    add_index :pending_task_evaluations, :created_at
    add_foreign_key :pending_task_evaluations, :tasks, on_delete: :cascade
    add_foreign_key :pending_task_evaluations, :trial_state_update_events, on_delete: :cascade

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION
            create_pending_task_evaluation_on_trial_state_update_event_insert()
          RETURNS TRIGGER AS $$
          DECLARE
            t_id UUID;
          BEGIN
             SELECT task_id INTO t_id
                FROM trials
                WHERE trials.id = NEW.trial_id;
             INSERT INTO pending_task_evaluations
              (task_id, trial_state_update_event_id) VALUES (t_id, NEW.id);
             RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL
        execute <<-SQL.strip_heredoc
          CREATE TRIGGER
            create_pending_task_evaluation_on_trial_state_update_event_insert
          AFTER INSERT ON trial_state_update_events FOR EACH ROW
          EXECUTE PROCEDURE
            create_pending_task_evaluation_on_trial_state_update_event_insert();
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER
            create_pending_task_evaluation_on_trial_state_update_event_insert
            ON trial_state_update_events ;
          DROP FUNCTION
            create_pending_task_evaluation_on_trial_state_update_event_insert();
        SQL
      end
    end

  end
end
