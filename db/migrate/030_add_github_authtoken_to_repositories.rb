class AddGithubAuthtokenToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :github_authtoken, :text
  end
end
