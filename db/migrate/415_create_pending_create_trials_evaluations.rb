require Rails.root.join("db","migrate","migration_helper.rb")

class CreatePendingCreateTrialsEvaluations < ActiveRecord::Migration
  include MigrationHelper
  def change
    create_table :pending_create_trials_evaluations, id: :uuid do |t|
      t.uuid :task_id, index: true, null: false
      t.uuid :trial_state_update_event_id
    end
    add_auto_timestamps :pending_create_trials_evaluations, updated_at: false
    add_index :pending_create_trials_evaluations, :created_at
    add_foreign_key :pending_create_trials_evaluations, :tasks, on_delete: :cascade
    add_foreign_key :pending_create_trials_evaluations, :trial_state_update_events, on_delete: :cascade

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION create_pending_create_trials_evaluations_on_tasks_insert()
          RETURNS TRIGGER AS $$
          BEGIN
             INSERT INTO pending_create_trials_evaluations
              (task_id) VALUES (NEW.id);
             RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL
        execute <<-SQL.strip_heredoc
          CREATE TRIGGER create_pending_create_trials_evaluations_on_tasks_insert
          AFTER INSERT ON tasks FOR EACH ROW
          EXECUTE PROCEDURE create_pending_create_trials_evaluations_on_tasks_insert();
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER create_pending_create_trials_evaluations_on_tasks_insert ON tasks;
          DROP FUNCTION create_pending_create_trials_evaluations_on_tasks_insert();
        SQL
      end
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION create_pending_create_trials_evaluations_on_trial_state_change()
          RETURNS TRIGGER AS $$
          DECLARE
            task_id UUID;
          BEGIN
             SELECT trials.task_id INTO task_id
                FROM trials
                WHERE trials.id = NEW.trial_id;
             INSERT INTO pending_create_trials_evaluations
              (task_id, trial_state_update_event_id) VALUES (task_id, NEW.id);
             RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL
        execute <<-SQL.strip_heredoc
          CREATE TRIGGER create_pending_create_trials_evaluations_on_trial_state_change
          AFTER INSERT ON trial_state_update_events FOR EACH ROW
          WHEN (NEW.state IN (#{Settings[:constants][:STATES][:FINISHED].map{|s|"'#{s}'"}.join(', ')}))
          EXECUTE PROCEDURE create_pending_create_trials_evaluations_on_trial_state_change();
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER create_pending_create_trials_evaluations_on_trial_state_change ON trial_state_update_events;
          DROP FUNCTION create_pending_create_trials_evaluations_on_trial_state_change();
        SQL
      end
    end

  end
end
