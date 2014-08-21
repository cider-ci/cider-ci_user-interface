class CreateTreeAttachments < ActiveRecord::Migration
  def change
    create_table :tree_attachments, id: :uuid do |t|
      t.text :path, null: false
      t.text :content_length
      t.text :content_type
      t.timestamp :to_be_retained_before
      t.timestamps null: false
      t.index [:path], unique: true
    end

    reversible do |dir|
      dir.up do
        #execute %< ALTER TABLE tree_attachments ALTER COLUMN to_be_deleted_after SET DEFAULT now() + interval '10 Days'>
        execute "ALTER TABLE tree_attachments ALTER COLUMN created_at SET DEFAULT now()";
        execute "ALTER TABLE tree_attachments ALTER COLUMN updated_at SET DEFAULT now()";
        execute %[CREATE TRIGGER update_updated_at_column_of_tree_attachments BEFORE UPDATE
                ON tree_attachments FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]
      end
    end
  end
end
