class CreateJobStats < ActiveRecord::Migration
  def change

    execute %{
        DROP VIEW IF EXISTS job_stats; 

        CREATE OR REPLACE VIEW job_stats AS
          SELECT jobs.id as job_id, 
          (select count(*) from tasks where tasks.job_id = jobs.id) as total,
          (select count(*) from tasks where tasks.job_id = jobs.id and state = 'aborted') as aborted,
          (select count(*) from tasks where tasks.job_id = jobs.id and state = 'skipped') as skipped,
          (select count(*) from tasks where tasks.job_id = jobs.id and state = 'executing') as executing,
          (select count(*) from tasks where tasks.job_id = jobs.id and state = 'failed') as failed,
          (select count(*) from tasks where tasks.job_id = jobs.id and state = 'passed') as passed,
          (select count(*) from tasks where tasks.job_id = jobs.id and state = 'pending') as pending 
          FROM jobs

    }

  end
end
