class AddStates < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          ALTER TABLE jobs DROP CONSTRAINT IF EXISTS check_jobs_valid_state;
          ALTER TABLE jobs ADD CONSTRAINT check_jobs_valid_state CHECK
          (state IN (#{ Settings[:constants][:STATES][:JOB].map{|s|"'#{s}'"}.join(', ')}));

          ALTER TABLE tasks DROP CONSTRAINT IF EXISTS check_tasks_valid_state;
          ALTER TABLE tasks ADD CONSTRAINT check_tasks_valid_state CHECK
          (state IN (#{Settings[:constants][:STATES][:TASK].map{|s|"'#{s}'"}.join(', ')}));

          ALTER TABLE trials DROP CONSTRAINT IF EXISTS check_trials_valid_state;
          ALTER TABLE trials DROP CONSTRAINT IF EXISTS check_trials_valid_state;
          ALTER TABLE trials ADD CONSTRAINT check_trials_valid_state CHECK
          (state IN (#{Settings[:constants][:STATES][:TRIAL].map{|s|"'#{s}'"}.join(', ')}));

          ALTER TABLE scripts DROP CONSTRAINT IF EXISTS check_trials_valid_state;
          ALTER TABLE scripts DROP CONSTRAINT IF EXISTS check_scripts_valid_state;
          ALTER TABLE scripts DROP CONSTRAINT IF EXISTS check_scripts_valid_state;
          ALTER TABLE scripts ADD CONSTRAINT check_scripts_valid_state CHECK
          (state IN (#{Settings[:constants][:STATES][:SCRIPT].map{|s|"'#{s}'"}.join(', ')}));

          DROP VIEW IF EXISTS job_stats;
          CREATE OR REPLACE VIEW job_stats AS
            SELECT jobs.id as job_id,
             (select count(*) from tasks where tasks.job_id = jobs.id) as total,
            #{ Settings[:constants][:STATES][:JOB].map{|state|
              "(select count(*) from tasks where tasks.job_id = jobs.id and state = '" + state +"') AS " + state
              }.join(", ")}
            FROM jobs;
        SQL
      end
    end
  end
end
