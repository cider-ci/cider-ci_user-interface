class AddPutAttachmentPermissionsForExecutors < ActiveRecord::Migration
  def change

    add_column :executors, :upload_tree_attachments, :boolean, default: false, null: false
    add_column :executors, :upload_trial_attachments, :boolean, default: true, null: false

    reversible do |dir|
      dir.up do
        execute <<-SQL

          DROP VIEW executors_with_load;

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
