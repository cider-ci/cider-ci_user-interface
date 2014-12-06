class ConsistentStateAttributes < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do

        execute <<-SQL
          DROP VIEW execution_stats; 

          CREATE OR REPLACE VIEW execution_stats AS
            SELECT executions.id as execution_id, 
            (select count(*) from tasks where tasks.execution_id = executions.id) as total,
            (select count(*) from tasks where tasks.execution_id = executions.id and state = 'aborted') as aborted,
            (select count(*) from tasks where tasks.execution_id = executions.id and state = 'executing') as executing,
            (select count(*) from tasks where tasks.execution_id = executions.id and state = 'failed') as failed,
            (select count(*) from tasks where tasks.execution_id = executions.id and state = 'passed') as passed,
            (select count(*) from tasks where tasks.execution_id = executions.id and state = 'pending') as pending 
            FROM executions
        SQL

        execute %[ALTER TABLE trials DROP CONSTRAINT valid_state]


        execute %[UPDATE executions SET state = 'passed' WHERE state = 'success']
        execute %[UPDATE tasks SET state = 'passed' WHERE state = 'success']
        execute %[UPDATE trials SET state = 'passed' WHERE state = 'success']

        execute %[ALTER TABLE executions ADD CONSTRAINT check_executions_valid_state CHECK 
          (state IN (#{Constants::EXECUTION_STATES.map{|s|"'#{s}'"}.join(', ')}));]

        execute %[ALTER TABLE tasks ADD CONSTRAINT check_tasks_valid_state CHECK 
          (state IN (#{Constants::TASK_STATES.map{|s|"'#{s}'"}.join(', ')}));]

        execute %[ALTER TABLE trials ADD CONSTRAINT check_trials_valid_state CHECK 
          (state IN (#{Constants::TRIAL_STATES.map{|s|"'#{s}'"}.join(', ')}));]

      end

      dir.down do
      end

    end
  end
end
