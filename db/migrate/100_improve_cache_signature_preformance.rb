class ImproveCacheSignaturePreformance < ActiveRecord::Migration
  def change
    add_index :tasks, [:execution_id,:updated_at]
    add_index :tasks, [:execution_id, :state]

    reversible do |dir| 

      dir.up do 

        execute <<-SQL
          DROP VIEW  IF EXISTS  execution_cache_signatures;

          CREATE OR REPLACE VIEW execution_cache_signatures AS

          SELECT executions.id as execution_id,
          md5(string_agg(DISTINCT branches.updated_at::text,', 'ORDER BY branches.updated_at::text)) AS branches_signature,
          md5(string_agg(DISTINCT commits.updated_at::text,', 'ORDER BY commits.updated_at::text)) AS commits_signature,
          md5(string_agg(DISTINCT repositories.updated_at::text,', 'ORDER BY repositories.updated_at::text)) AS repositories_signature,
          (SELECT (md5(string_agg(executions_tags.tag_id::text,',' ORDER BY tag_id))) FROM executions_tags WHERE executions_tags.execution_id = executions.id) AS tags_signature,
          (SELECT (count(DISTINCT tasks.id)::text || ' - ' || max(tasks.updated_at)::text ) FROM tasks WHERE tasks.execution_id = executions.id) as tasks_signature
          FROM executions
          LEFT OUTER JOIN commits ON executions.tree_id = commits.tree_id
          LEFT OUTER JOIN branches_commits ON branches_commits.commit_id = commits.id
          LEFT OUTER JOIN branches ON branches_commits.branch_id= branches.id
          LEFT OUTER JOIN repositories ON branches.repository_id= repositories.id
          GROUP BY executions.id;

        SQL
      end
    end
  end
end
