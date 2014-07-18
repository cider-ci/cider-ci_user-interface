class CreateTrialAttachments < ActiveRecord::Migration
  def change
    create_table :trial_attachments, id: :uuid do |t|
      t.text :path, null: false
      t.text :content_length
      t.text :content_type
      t.timestamp :to_be_retained_before
      t.timestamps null: false
      t.index [:path], unique: true
    end

    reversible do |dir|
      dir.up do
        #execute %< ALTER TABLE trial_attachments ALTER COLUMN to_be_deleted_after SET DEFAULT now() + interval '10 Days'>
        execute "ALTER TABLE trial_attachments ALTER COLUMN created_at SET DEFAULT now()";
        execute "ALTER TABLE trial_attachments ALTER COLUMN updated_at SET DEFAULT now()";
        execute %[CREATE TRIGGER update_updated_at_column_of_trial_attachments BEFORE UPDATE
                ON trial_attachments FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]
      end
    end
  end
end
