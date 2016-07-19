class AddLoadToTasks < ActiveRecord::Migration
  def change

    execute 'DROP VIEW executors_with_load;'

    add_column :tasks, :load, :float, nil: false, default: 1.0
    execute <<-SQL.strip_heredoc
      ALTER TABLE tasks
        ADD CONSTRAINT load_is_stricly_positive CHECK (load > 0)
    SQL

    change_column :executors, :max_load, :float,
      nil: false, default: 1.0
    execute <<-SQL.strip_heredoc
      ALTER TABLE executors
        ADD CONSTRAINT max_load_is_positive CHECK (max_load >= 0)
     SQL

    add_column :executors, :temporary_overload_factor, :float,
      nil: false, default: 1.5
    execute <<-SQL.strip_heredoc
      ALTER TABLE executors
        ADD CONSTRAINT sensible_temoporary_overload_factor
          CHECK (temporary_overload_factor >= 1.0)
     SQL

    execute <<-SQL.strip_heredoc
      CREATE OR REPLACE VIEW executors_load AS
        SELECT count(trials.id) AS trials_count,
          sum(COALESCE(tasks.load, 0.0)) AS current_load,
          executors.id AS executor_id
          FROM executors
          LEFT OUTER JOIN trials ON trials.executor_id = executors.id
            AND trials.state IN ('aborting', 'dispatching', 'executing')
          LEFT OUTER JOIN tasks ON tasks.id = trials.task_id
          GROUP BY executors.id;
    SQL

    execute <<-SQL.strip_heredoc
      CREATE OR REPLACE VIEW executors_with_load AS
        SELECT executors.*, executors_load.*,
          executors_load.current_load/executors.max_load relative_load
        FROM executors
          JOIN executors_load ON executors_load.executor_id = executors.id
    SQL

  end
end
