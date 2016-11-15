module MigrationHelper extend ActiveSupport::Concern

  def create_trgm_index(t, c)
    execute "CREATE INDEX ON #{t} USING gin(#{c} gin_trgm_ops);"
  end

  def create_text_index(t, c)
    reversible do |dir|
      dir.up do
        execute "CREATE INDEX ON #{t} USING gin(to_tsvector('english',#{c}));"
      end
    end
  end

  def add_auto_timestamps(table_name, created_at: true, updated_at: true)
    reversible do |dir|
      dir.up do

        if created_at
          add_column(table_name, :created_at, 'timestamp with time zone')
          execute "ALTER TABLE #{table_name} ALTER COLUMN created_at SET DEFAULT now()"
          execute "ALTER TABLE #{table_name} ALTER COLUMN created_at SET NOT NULL"
        end

        if updated_at
          add_column(table_name, :updated_at, 'timestamp with time zone')
          execute "ALTER TABLE #{table_name} ALTER COLUMN updated_at SET DEFAULT now()"
          execute "ALTER TABLE #{table_name} ALTER COLUMN updated_at SET NOT NULL"

          execute <<-SQL.strip_heredoc
            CREATE OR REPLACE FUNCTION update_updated_at_column()
            RETURNS TRIGGER AS $$
            BEGIN
               NEW.updated_at = now();
               RETURN NEW;
            END;
            $$ language 'plpgsql';
          SQL

          execute <<-SQL.strip_heredoc
            CREATE TRIGGER update_updated_at_column_of_#{table_name}
            BEFORE UPDATE ON #{table_name} FOR EACH ROW
            WHEN (OLD.* IS DISTINCT FROM NEW.*)
            EXECUTE PROCEDURE
            update_updated_at_column();
          SQL
        end
      end

      dir.down do
        execute " DROP TRIGGER IF EXISTS update_updated_at_column_of_#{table_name} ON #{table_name} "
        if created_at
          remove_column(table_name, :created_at)
        end
        if updated_at
          remove_column(table_name, :updated_at)
        end
      end
    end
  end


  def add_or_replace_events_table table_name

    entity_name = table_name.singularize

    event_table_name = "#{entity_name}_events"
    trigger_name = event_table_name.singularize


    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          DROP TABLE IF EXISTS #{event_table_name} CASCADE;
          DROP TRIGGER IF EXISTS #{trigger_name} ON #{table_name} CASCADE;
          DROP FUNCTION IF EXISTS clean_#{event_table_name}() CASCADE;
        SQL
      end
    end

    create_table event_table_name, id: :uuid  do |t|
      t.uuid "#{entity_name}_id", index: true
      t.text :event
    end

    reversible do |dir|

      dir.up do
        add_auto_timestamps event_table_name, updated_at: false

        execute <<-SQL.strip_heredoc

          CREATE OR REPLACE FUNCTION #{trigger_name}()
          RETURNS TRIGGER AS $$
          BEGIN
            CASE
              WHEN TG_OP = 'DELETE' THEN
                INSERT INTO #{event_table_name}
                  (#{entity_name}_id, event) VALUES (OLD.id, TG_OP);
              WHEN TG_OP = 'TRUNCATE' THEN
                INSERT INTO #{event_table_name} (event) VALUES (TG_OP);
              ELSE
                INSERT INTO #{event_table_name}
                  (#{entity_name}_id, event) VALUES (NEW.id, TG_OP);
            END CASE;
            RETURN NULL;
          END;
          $$ language 'plpgsql';

          DROP TRIGGER IF EXISTS #{trigger_name} ON #{table_name};
          CREATE TRIGGER #{trigger_name}
            AFTER INSERT OR DELETE OR UPDATE
            ON #{table_name}
            FOR EACH ROW EXECUTE PROCEDURE #{trigger_name}();

          DROP TRIGGER IF EXISTS #{trigger_name}_truncate ON #{table_name};
          CREATE TRIGGER #{trigger_name}_truncate
            AFTER TRUNCATE
            ON #{table_name}
            EXECUTE PROCEDURE #{trigger_name}();

         SQL
      end

      dir.down do

        execute <<-SQL.strip_heredoc

          DROP TRIGGER #{trigger_name} ON #{table_name};
          DROP TRIGGER #{trigger_name}_truncate ON #{table_name};
          DROP FUNCTION #{trigger_name}();

        SQL

      end


    end

    ### clean old events ######################################################

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION clean_#{event_table_name}()
          RETURNS trigger AS $$
          BEGIN
            DELETE FROM #{event_table_name}
              WHERE created_at < NOW() - INTERVAL '3 days';
            RETURN NULL;
          END;
          $$ language 'plpgsql';
        SQL

        execute <<-SQL.strip_heredoc
          CREATE TRIGGER clean_#{event_table_name}
          AFTER INSERT ON #{event_table_name} FOR EACH STATEMENT
          EXECUTE PROCEDURE clean_#{event_table_name}();
        SQL
      end

      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER clean_#{event_table_name} ON #{event_table_name};
          DROP FUNCTION clean_#{event_table_name}();
        SQL
      end
    end
  end

end
