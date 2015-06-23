class AddAcceptedRepositoriesToExecutors < ActiveRecord::Migration
  def change
    add_column :executors, :accepted_repositories, :string, array: true, default: '{}'
    add_index :executors, :accepted_repositories
    rename_column :repositories, :origin_uri, :git_url
    add_index :repositories, :git_url, unique: true

    reversible do |dir|
      dir.down do
        execute "DROP VIEW executors_with_load"
      end
      dir.up do
        execute <<-SQL

          DROP VIEW IF EXISTS executors_with_load;

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
  end
end
