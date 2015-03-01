class AdjustExecutorProperties < ActiveRecord::Migration
  def change

    execute "DROP VIEW executors_with_load"

    remove_column :executors, :host, :string, null: false
    remove_column :executors, :port, :integer, null: false, default: 8443
    remove_column :executors, :ssl, :boolean, null: false, default: true

    remove_column :executors, :server_overwrite, :boolean, default: false
    remove_column :executors, :server_ssl, :boolean, default: true
    remove_column :executors, :server_host, :string, default: '192.168.0.1'
    remove_column :executors, :server_port, :integer, default: '8080'

    remove_column :executors, :app, :string
    remove_column :executors, :app_version, :string
  
    add_column :executors, :base_url, :string
    # execute %q< ALTER TABLE executors ADD CONSTRAINT executors_base_url_constraints CHECK ( (base_url ~* '^http[s|]\:\/\/\S+$') OR base_url IS NULL ); >

    remove_index :executors, :name

    execute "CREATE UNIQUE INDEX executors_on_lower_name_idx ON executors(lower(name))"

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
