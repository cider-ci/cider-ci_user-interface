require Rails.root.join("db","migrate","migration_helper.rb")

class CreateStateUpdateEvents < ActiveRecord::Migration
  include MigrationHelper

  def change

    entities = [
      { table_name: "job_state_update_events",
        entity_name: "job" },
      { table_name: "task_state_update_events",
        entity_name: "task" },
      { table_name: "trial_state_update_events",
        entity_name: "trial" },
      { table_name: "script_state_update_events",
        entity_name: "script" },
    ]

    entities.each do |params|

      table_name = params[:table_name]
      entity_name = params[:entity_name]
      trigger_name = "create_#{table_name}"
      referenced_table = entity_name.pluralize

      create_table table_name, id: :uuid do |t|
        t.uuid "#{entity_name}_id", index: true
        t.string :state
      end

      add_auto_timestamps table_name, updated_at: false
      add_index table_name, :created_at
      add_foreign_key table_name, referenced_table, on_delete: :cascade

      ### state constraint ######################################################
      reversible do |dir|
        dir.up do
          execute <<-SQL.strip_heredoc
            ALTER TABLE #{table_name}
                DROP CONSTRAINT IF EXISTS check_valid_state;
            ALTER TABLE #{table_name} ADD CONSTRAINT check_valid_state CHECK
            (state IN (#{ Settings[:constants][:STATES][entity_name.upcase.to_sym].map{|s|"'#{s}'"}.join(', ')}));
          SQL
        end
      end


      ### insert trigger ########################################################
      reversible do |dir|
        dir.up do

          execute <<-SQL.strip_heredoc
            CREATE OR REPLACE FUNCTION #{trigger_name}()
            RETURNS TRIGGER AS $$
            BEGIN
               INSERT INTO #{table_name}
                (#{entity_name}_id, state) VALUES (New.id, NEW.state);
               RETURN NEW;
            END;
            $$ language 'plpgsql';
          SQL

          execute <<-SQL.strip_heredoc
            CREATE TRIGGER #{trigger_name}_on_insert
            AFTER INSERT ON #{referenced_table} FOR EACH ROW
            EXECUTE PROCEDURE #{trigger_name}();
          SQL

          execute <<-SQL.strip_heredoc
            CREATE TRIGGER #{trigger_name}_on_update
            AFTER UPDATE ON #{referenced_table} FOR EACH ROW
            WHEN (OLD.state IS DISTINCT FROM NEW.state)
            EXECUTE PROCEDURE #{trigger_name}();
          SQL


        end

        dir.down do
          execute <<-SQL.strip_heredoc
            DROP TRIGGER #{trigger_name}_on_insert ON #{referenced_table};
            DROP TRIGGER #{trigger_name}_on_update ON #{referenced_table};
          SQL
        end
      end


      ### clean old events ######################################################

      reversible do |dir|
        dir.up do
          execute <<-SQL.strip_heredoc
            CREATE OR REPLACE FUNCTION clean_#{table_name}()
            RETURNS trigger AS $$
            BEGIN
              DELETE FROM #{table_name}
                WHERE created_at < NOW() - INTERVAL '3 days';
              RETURN NULL;
            END;
            $$ language 'plpgsql';
          SQL

          execute <<-SQL.strip_heredoc
            CREATE TRIGGER clean_#{table_name}
            AFTER INSERT ON #{table_name} FOR EACH STATEMENT
            EXECUTE PROCEDURE clean_#{table_name}();
          SQL
        end

        dir.down do
          execute <<-SQL.strip_heredoc
            DROP TRIGGER clean_#{table_name} ON #{table_name};
            DROP FUNCTION clean_#{table_name}();
          SQL
        end
      end

    end
  end
end


