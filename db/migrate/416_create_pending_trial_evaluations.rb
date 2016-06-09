require Rails.root.join("db","migrate","migration_helper.rb")

class CreatePendingTrialEvaluations < ActiveRecord::Migration
  include MigrationHelper

  def change
    create_table :pending_trial_evaluations, uuid: true do |t|
      t.uuid :trial_id, null: false
      t.uuid :script_state_update_event_id
    end
    add_auto_timestamps :pending_trial_evaluations, updated_at: false
    add_index :pending_trial_evaluations, :created_at
    add_foreign_key :pending_trial_evaluations, :trials, on_delete: :cascade
    add_foreign_key :pending_trial_evaluations, :script_state_update_events, on_delete: :cascade

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION
            create_pending_trial_evaluation_on_script_state_update_event_insert()
          RETURNS TRIGGER AS $$
          DECLARE
            t_id UUID;
          BEGIN
             SELECT trial_id INTO t_id
                FROM scripts
                WHERE scripts.id = NEW.script_id;
             INSERT INTO pending_trial_evaluations
              (trial_id, script_state_update_event_id) VALUES (t_id, NEW.id);
             RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL
        execute <<-SQL.strip_heredoc
          CREATE TRIGGER
            create_pending_trial_evaluation_on_script_state_update_event_insert
          AFTER INSERT ON script_state_update_events FOR EACH ROW
          EXECUTE PROCEDURE
            create_pending_trial_evaluation_on_script_state_update_event_insert();
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER
            create_pending_trial_evaluation_on_script_state_update_event_insert
            ON script_state_update_events ;
          DROP FUNCTION
            create_pending_trial_evaluation_on_script_state_update_event_insert();
        SQL
      end
    end


  end
end
