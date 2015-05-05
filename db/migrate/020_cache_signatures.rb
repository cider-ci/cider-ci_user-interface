class CacheSignatures < ActiveRecord::Migration
  def change

    reversible do |dir| 
      dir.up do 
        execute <<-SQL
        DROP VIEW  IF EXISTS  job_cache_signatures;

        CREATE OR REPLACE VIEW job_cache_signatures AS
          SELECT jobs.id as job_id,
            md5(string_agg(DISTINCT branches.updated_at::text,', 'ORDER BY branches.updated_at::text)) AS branches_signature,
            md5(string_agg(DISTINCT commits.updated_at::text,', 'ORDER BY commits.updated_at::text)) AS commits_signature,
            md5(string_agg(DISTINCT job_issues.updated_at::text,', 'ORDER BY job_issues.updated_at::text)) AS job_issues_signature,
            count(DISTINCT job_issues) AS job_issues_count,
            md5(string_agg(DISTINCT repositories.updated_at::text,', 'ORDER BY repositories.updated_at::text)) AS repositories_signature,
            (SELECT (md5(string_agg(jobs_tags.tag_id::text,',' ORDER BY tag_id))) FROM jobs_tags WHERE jobs_tags.job_id = jobs.id) AS tags_signature,
            (SELECT (count(DISTINCT tasks.id)::text || ' - ' || max(tasks.updated_at)::text ) FROM tasks WHERE tasks.job_id = jobs.id) as tasks_signature
          FROM jobs
          LEFT OUTER JOIN job_issues ON jobs.id = job_issues.job_id
          LEFT OUTER JOIN commits ON jobs.tree_id = commits.tree_id
          LEFT OUTER JOIN branches_commits ON branches_commits.commit_id = commits.id
          LEFT OUTER JOIN branches ON branches_commits.branch_id= branches.id
          LEFT OUTER JOIN repositories ON branches.repository_id= repositories.id
          GROUP BY jobs.id;
        SQL


        execute <<-SQL
          DROP VIEW IF EXISTS commit_cache_signatures;
          CREATE OR REPLACE VIEW commit_cache_signatures AS
            SELECT commits.id AS commit_id,
                   md5(string_agg(DISTINCT branches.updated_at::text,', 'ORDER BY branches.updated_at::text)) AS branches_signature,
                   md5(string_agg(DISTINCT repositories.updated_at::text,', 'ORDER BY repositories.updated_at::text)) AS repositories_signature,
                   md5(string_agg(DISTINCT jobs.updated_at::text,', 'ORDER BY jobs.updated_at::text)) AS jobs_signature
            FROM commits
            LEFT OUTER JOIN branches_commits ON branches_commits.commit_id = commits.id
            LEFT OUTER JOIN branches ON branches_commits.branch_id= branches.id
            LEFT OUTER JOIN jobs ON jobs.tree_id = commits.tree_id
            LEFT OUTER JOIN repositories ON branches.repository_id= repositories.id
            GROUP BY commits.id
        SQL

      end
    end
  end

end
