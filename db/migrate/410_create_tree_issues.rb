require Rails.root.join("db","migrate","migration_helper.rb")

class CreateTreeIssues < ActiveRecord::Migration
  include MigrationHelper

  def change
    create_table :tree_issues, id: :uuid do |t|
      t.text :title
      t.text :description
      t.string :type, null: false, default: 'error'
      t.text "tree_id", null: false
      t.index "tree_id"
    end

    add_auto_timestamps 'tree_issues'

    execute <<-SQL.strip_heredoc
      DROP VIEW IF EXISTS commit_cache_signatures;
      CREATE OR REPLACE VIEW commit_cache_signatures AS
        SELECT commits.id AS commit_id,
               count(tree_issues) > 0 AS has_tree_issues,
               md5(string_agg(DISTINCT branches.updated_at::text,',
                    'ORDER BY branches.updated_at::text)) AS branches_signature,
               md5(string_agg(DISTINCT repositories.updated_at::text,',
                    'ORDER BY repositories.updated_at::text)) AS repositories_signature,
               md5(string_agg(DISTINCT jobs.updated_at::text,',
                    'ORDER BY jobs.updated_at::text)) AS jobs_signature
        FROM commits
        LEFT OUTER JOIN branches_commits ON branches_commits.commit_id = commits.id
        LEFT OUTER JOIN branches ON branches_commits.branch_id= branches.id
        LEFT OUTER JOIN jobs ON jobs.tree_id = commits.tree_id
        LEFT OUTER JOIN repositories ON branches.repository_id= repositories.id
        LEFT OUTER JOIN tree_issues ON tree_issues.tree_id = commits.tree_id
        GROUP BY commits.id;
    SQL

  end
end
