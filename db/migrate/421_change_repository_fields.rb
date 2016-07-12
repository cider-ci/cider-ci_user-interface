class ChangeRepositoryFields < ActiveRecord::Migration
  def change

    add_column :repositories, :foreign_api_token_bearer, :string

    change_column :repositories, :foreign_api_endpoint, :string, null: true, default: nil
    change_column :repositories, :foreign_api_authtoken, :string, null: true, default: nil
    change_column :repositories, :foreign_api_owner, :string, null: true, default: nil
    change_column :repositories, :foreign_api_repo, :string, null: true, default: nil

    Repository.find_each do |repo|
      repo.update_attributes! foreign_api_endpoint: repo.foreign_api_endpoint.presence
      repo.update_attributes! foreign_api_authtoken: repo.foreign_api_authtoken.presence
      repo.update_attributes! foreign_api_owner: repo.foreign_api_owner.presence
      repo.update_attributes! foreign_api_repo: repo.foreign_api_repo.presence
    end

    execute <<-SQL.strip_heredoc
      ALTER TABLE repositories
        ADD CONSTRAINT foreign_api_token_bearer_not_empty
        CHECK (foreign_api_token_bearer <> '');
      ALTER TABLE repositories
        ADD CONSTRAINT foreign_api_endpoint_not_empty
        CHECK (foreign_api_endpoint <> '');
      ALTER TABLE repositories
        ADD CONSTRAINT foreign_api_authtoken_not_empty
        CHECK (foreign_api_authtoken <> '');
      ALTER TABLE repositories
        ADD CONSTRAINT foreign_api_owner_not_empty
        CHECK (foreign_api_owner <> '');
      ALTER TABLE repositories
        ADD CONSTRAINT foreign_api_repo_not_empty
        CHECK (foreign_api_repo <> '');
    SQL

  end
end
