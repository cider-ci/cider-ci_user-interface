class AddPublicViewPermissionToRepos < ActiveRecord::Migration
  def change
    add_column :repositories, :public_view_permission, :boolean, default: false, null: false
  end
end
