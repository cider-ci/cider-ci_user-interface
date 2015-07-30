class RemoveGitUpdateIntervalFromRepositories < ActiveRecord::Migration
  def change
    remove_column :repositories, :git_update_interval, :integer
    change_column :repositories, :git_url, :text, null: false
  end
end
