class AddAbortingState < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do

        execute %[ ALTER TABLE jobs DROP CONSTRAINT IF EXISTS check_jobs_valid_state;
          ALTER TABLE jobs ADD CONSTRAINT check_jobs_valid_state CHECK
          (state IN (#{Settings.constants.STATES.JOB.map{|s|"'#{s}'"}.join(', ')}));]

        execute %[ ALTER TABLE tasks DROP CONSTRAINT IF EXISTS check_tasks_valid_state;
          ALTER TABLE tasks ADD CONSTRAINT check_tasks_valid_state CHECK
          (state IN (#{Settings.constants.STATES.TASK.map{|s|"'#{s}'"}.join(', ')}));]

        execute %[ ALTER TABLE trials DROP CONSTRAINT IF EXISTS valid_state;
          ALTER TABLE trials DROP CONSTRAINT IF EXISTS check_trials_valid_state;
          ALTER TABLE trials ADD CONSTRAINT check_trials_valid_state CHECK
          ( state IN (#{Settings.constants.STATES.TRIAL.map{|s|"'#{s}'"}.join(', ')}));]

        execute %[
          DROP VIEW IF EXISTS job_stats;
          CREATE OR REPLACE VIEW job_stats AS
            SELECT jobs.id as job_id,
             (select count(*) from tasks where tasks.job_id = jobs.id) as total,
            #{ Settings.constants.STATES.JOB.map{|state|
              "(select count(*) from tasks where tasks.job_id = jobs.id and state = '" + state +"') AS " + state
              }.join(", ")}
            FROM jobs
          ]
      end
    end
  end
end
