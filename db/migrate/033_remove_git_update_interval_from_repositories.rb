class RemoveGitUpdateIntervalFromRepositories < ActiveRecord::Migration
  def change
    remove_column :repositories, :git_update_interval
  end
end
