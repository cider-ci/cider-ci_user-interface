class UpdateJobCacheSignatures < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do
        execute <<-SQL
        DROP VIEW  IF EXISTS  job_cache_signatures;

        CREATE OR REPLACE VIEW job_cache_signatures AS
          SELECT jobs.id as job_id,
            md5(string_agg(DISTINCT branches.updated_at::text,',
               'ORDER BY branches.updated_at::text)) AS branches_signature,
            md5(string_agg(DISTINCT commits.updated_at::text,',
               'ORDER BY commits.updated_at::text)) AS commits_signature,
            md5(string_agg(DISTINCT job_issues.updated_at::text,',
               'ORDER BY job_issues.updated_at::text)) AS job_issues_signature,
            count(DISTINCT job_issues) AS job_issues_count,
            md5(string_agg(DISTINCT repositories.updated_at::text,',
               'ORDER BY repositories.updated_at::text)) AS repositories_signature,
            (SELECT (count(DISTINCT tasks.id)::text || ' - ' || max(tasks.updated_at)::text )
              FROM tasks WHERE tasks.job_id = jobs.id) as tasks_signature,
            (SELECT count(DISTINCT id) FROM tree_attachments
              WHERE tree_attachments.tree_id= jobs.tree_id) AS tree_attachments_count
          FROM jobs
          LEFT OUTER JOIN job_issues ON jobs.id = job_issues.job_id
          LEFT OUTER JOIN commits ON jobs.tree_id = commits.tree_id
          LEFT OUTER JOIN branches_commits ON branches_commits.commit_id = commits.id
          LEFT OUTER JOIN branches ON branches_commits.branch_id= branches.id
          LEFT OUTER JOIN repositories ON branches.repository_id= repositories.id
          GROUP BY jobs.id;
        SQL

      end
    end
  end

end
