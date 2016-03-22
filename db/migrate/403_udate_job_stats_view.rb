class UdateJobStatsView < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc

          DROP VIEW IF EXISTS job_stats;
          CREATE OR REPLACE VIEW job_stats AS
            SELECT jobs.id as job_id,
             (select count(*) from tasks where tasks.job_id = jobs.id) as total,
        #{ Settings[:constants][:STATES][:JOB].map{|state|
        "(select count(*) from tasks where tasks.job_id = jobs.id and state = '" + state +"') AS " + state
        }.join(", ")}
            FROM jobs

        SQL

      end
    end
  end
end
