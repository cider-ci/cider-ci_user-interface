class CreateTrialIssues < ActiveRecord::Migration
  def change
    create_table :trial_issues, id: :uuid do |t|
      t.text :title
      t.text :description
      t.string :type, null: false, default: 'error'
      t.uuid :trial_id, null: false
      t.index :trial_id
      t.timestamps
    end
    add_foreign_key :trial_issues, :trials, dependent: :delete

    reversible do |dir| 

      dir.up do 
        execute "ALTER TABLE trial_issues ADD CONSTRAINT valid_type CHECK 
                ( type IN ('error', 'warning') )"

        execute "ALTER TABLE trial_issues ALTER COLUMN created_at SET DEFAULT now()";
        execute "ALTER TABLE trial_issues ALTER COLUMN updated_at SET DEFAULT now()";
        execute %[CREATE TRIGGER update_updated_at_column_of_trial_issues BEFORE UPDATE
                ON trial_issues FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]
      end
    end
  end
end
