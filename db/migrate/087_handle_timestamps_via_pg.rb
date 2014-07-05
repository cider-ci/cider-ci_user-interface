class HandleTimestampsViaPg < ActiveRecord::Migration
  def up
    execute "ALTER TABLE attachments ALTER COLUMN created_at SET DEFAULT now()"
    execute "ALTER TABLE attachments ALTER COLUMN updated_at SET DEFAULT now()"
    execute %[CREATE TRIGGER update_updated_at_column_of_attachments BEFORE UPDATE
                ON attachments FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]

    execute "ALTER TABLE branch_update_triggers ALTER COLUMN created_at SET DEFAULT now()";
    execute "ALTER TABLE branch_update_triggers ALTER COLUMN updated_at SET DEFAULT now()";
    execute %[CREATE TRIGGER update_updated_at_column_of_branch_update_triggers BEFORE UPDATE
                ON branch_update_triggers FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]

    execute "ALTER TABLE executions ALTER COLUMN created_at SET DEFAULT now()"
    execute "ALTER TABLE executions ALTER COLUMN updated_at SET DEFAULT now()"
    execute %[CREATE TRIGGER update_updated_at_column_of_executions BEFORE UPDATE
                ON executions FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]

    execute "ALTER TABLE executors ALTER COLUMN created_at SET DEFAULT now()"
    execute "ALTER TABLE executors ALTER COLUMN updated_at SET DEFAULT now()"
    execute %[CREATE TRIGGER update_updated_at_column_of_executors BEFORE UPDATE
                ON executors FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]

    execute "ALTER TABLE repositories ALTER COLUMN created_at SET DEFAULT now()"
    execute "ALTER TABLE repositories ALTER COLUMN updated_at SET DEFAULT now()"
    execute %[CREATE TRIGGER update_updated_at_column_of_repositories BEFORE UPDATE
                ON repositories FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]

    execute "ALTER TABLE specifications ALTER COLUMN created_at SET DEFAULT now()"
    execute "ALTER TABLE specifications ALTER COLUMN updated_at SET DEFAULT now()"
    execute %[CREATE TRIGGER update_updated_at_column_of_specifications BEFORE UPDATE
                ON specifications FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]

    execute "ALTER TABLE tags ALTER COLUMN created_at SET DEFAULT now()"
    execute "ALTER TABLE tags ALTER COLUMN updated_at SET DEFAULT now()"
    execute %[CREATE TRIGGER update_updated_at_column_of_tags BEFORE UPDATE
                ON tags FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]

    execute "ALTER TABLE tasks ALTER COLUMN created_at SET DEFAULT now()"
    execute "ALTER TABLE tasks ALTER COLUMN updated_at SET DEFAULT now()"
    execute %[CREATE TRIGGER update_updated_at_column_of_tasks BEFORE UPDATE
                ON tasks FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]

    execute "ALTER TABLE timeout_settings ALTER COLUMN created_at SET DEFAULT now()"
    execute "ALTER TABLE timeout_settings ALTER COLUMN updated_at SET DEFAULT now()"
    execute %[CREATE TRIGGER update_updated_at_column_of_timeout_settings BEFORE UPDATE
                ON timeout_settings FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]

    execute "ALTER TABLE trials ALTER COLUMN created_at SET DEFAULT now()"
    execute "ALTER TABLE trials ALTER COLUMN updated_at SET DEFAULT now()"

    change_table :users do |t|
      t.timestamps
    end

    execute "ALTER TABLE users ALTER COLUMN created_at SET DEFAULT now()"
    execute "ALTER TABLE users ALTER COLUMN updated_at SET DEFAULT now()"
    execute %[CREATE TRIGGER update_updated_at_column_of_users BEFORE UPDATE
                ON users FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]


    execute "ALTER TABLE welcome_page_settings ALTER COLUMN created_at SET DEFAULT now()"
    execute "ALTER TABLE welcome_page_settings ALTER COLUMN updated_at SET DEFAULT now()"
    execute %[CREATE TRIGGER update_updated_at_column_of_welcome_page_settings BEFORE UPDATE
                ON welcome_page_settings FOR EACH ROW EXECUTE PROCEDURE 
                update_updated_at_column(); ]

  end

  def down
  end
end
