class AddUsersWorkspaceDefaultFilters < ActiveRecord::Migration
  def change
    add_column :users, :workspace_filters, :jsonb
  end
end
