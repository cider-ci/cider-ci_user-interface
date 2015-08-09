class RequireUniqueExecutorName < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do
        execute "DROP VIEW executors_with_load"
        change_column :executors, :name, :string, null: false
      end
    end

    add_index :executors, :name, unique: true

    reversible do |dir|
      dir.up do
        execute " CREATE OR REPLACE VIEW executors_with_load AS
                  SELECT executors.*,
                      count(trials.executor_id) AS current_load,
                      count(trials.executor_id)::float/executors.max_load::float AS relative_load
                    FROM executors
                    LEFT OUTER JOIN trials ON trials.executor_id = executors.id
                      AND trials.state IN ('dispatching', 'executing')
                    GROUP BY executors.id "
      end
    end
  end
end
