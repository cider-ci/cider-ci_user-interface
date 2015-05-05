require Rails.root.join("db","migrate","migration_helper.rb")
class CreateExecutors < ActiveRecord::Migration
  include MigrationHelper

  def change
    create_table :executors, id: :uuid do |t|

    t.string :name  

    t.integer :max_load, null: false, default: 1
    t.boolean :enabled, null: false, default: true

    t.string :traits, array: true, default: '{}'
    t.index :traits 

    t.text :base_url

    t.timestamp :last_ping_at

    end

    add_auto_timestamps :executors

    execute %q< ALTER TABLE executors ADD CONSTRAINT executors_name_constraints CHECK (name ~* '^[A-Za-z0-9\-\_]+$'); >

    execute <<-SQL

      CREATE OR REPLACE VIEW executors_with_load AS
        SELECT executors.*, 
            count(trials.executor_id) AS current_load,
            count(trials.executor_id)::float/executors.max_load::float AS relative_load
          FROM executors
          LEFT OUTER JOIN trials ON trials.executor_id = executors.id
            AND trials.state IN ('dispatching', 'executing')
          GROUP BY executors.id

    SQL


  end
end
