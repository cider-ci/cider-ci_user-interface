require Rails.root.join("db","migrate","migration_helper.rb")

class CreatePendingResultPropagations < ActiveRecord::Migration
  include MigrationHelper

  def change
    create_table :pending_result_propagations, id: :uuid do |t|
      t.uuid :trial_id, null: false
    end
    add_foreign_key :pending_result_propagations, :trials, on_delete: :cascade
    add_auto_timestamps :pending_result_propagations, updated_at: false
    add_index :pending_result_propagations, :created_at

    reversible do |dir|
      dir.up do

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION
            create_pending_result_propagation()
          RETURNS TRIGGER AS $$
          BEGIN
             INSERT INTO pending_result_propagations
              (trial_id) VALUES (NEW.id);
             RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL

        execute <<-SQL.strip_heredoc
          CREATE TRIGGER
            create_pending_result_propagation
          AFTER UPDATE ON trials FOR EACH ROW
          WHEN (OLD.result IS DISTINCT FROM NEW.result)
          EXECUTE PROCEDURE
            create_pending_result_propagation();
        SQL

      end

      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER create_pending_result_propagation ON trials;
          DROP FUNCTION create_pending_result_propagation();
        SQL
      end

    end


  end
end
