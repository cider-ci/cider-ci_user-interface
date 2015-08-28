class ResetUsersWorkspaceFilter < ActiveRecord::Migration
  def change
    execute 'UPDATE users SET workspace_filters = NULL'
  end
end
