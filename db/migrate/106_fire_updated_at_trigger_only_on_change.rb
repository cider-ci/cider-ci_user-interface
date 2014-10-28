class FireUpdatedAtTriggerOnlyOnChange < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        %w(branches commits execution_issues executions executors repositories 
        tags tree_attachments trial_attachments trials users).each do |table| 
          execute %[
                  DROP TRIGGER IF EXISTS update_updated_at_column_of_#{table} ON #{table};

                  CREATE TRIGGER update_updated_at_column_of_#{table}
                  BEFORE UPDATE ON #{table} FOR EACH ROW 
                  WHEN (OLD.* IS DISTINCT FROM NEW.*)
                  EXECUTE PROCEDURE 
                  update_updated_at_column(); ]
        end

      end
    end
  end
end
