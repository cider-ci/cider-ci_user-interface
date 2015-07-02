class AddGithubAuthtokenToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :github_authtoken, :text
    add_column :repositories, :use_default_github_authtoken, :boolean, default: false, null: false
  end
end
