class RenameRepositoryProperties < ActiveRecord::Migration
  def change

    execute <<-SQL.strip_heredoc
      ALTER TABLE repositories DROP CONSTRAINT check_valid_foreign_api_type;
    SQL


    rename_column :repositories, :foreign_api_repo, :remote_api_name
    rename_column :repositories, :foreign_api_owner, :remote_api_namespace
    rename_column :repositories, :foreign_api_authtoken, :remote_api_token
    rename_column :repositories, :foreign_api_token_bearer, :remote_api_token_bearer
    rename_column :repositories, :foreign_api_type, :remote_api_type
    rename_column :repositories, :foreign_api_endpoint, :remote_api_endpoint
    add_column :repositories, :remote_http_fetch_token, :text
    rename_column :repositories, :git_fetch_and_update_interval, :remote_fetch_interval

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          ALTER TABLE repositories ADD CONSTRAINT check_valid_remote_api_type CHECK
            (remote_api_type IN ('github', 'gitlab', 'bitbucket'));
        SQL
      end
    end

  end
end
