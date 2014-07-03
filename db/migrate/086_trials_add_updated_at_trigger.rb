class TrialsAddUpdatedAtTrigger < ActiveRecord::Migration

  def change

    execute %[CREATE TRIGGER update_updated_at_column_of_trials BEFORE UPDATE
                ON trials FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]

  end

end
