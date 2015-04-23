class RemoveUnusedRepositoriesFields < ActiveRecord::Migration
  def change
    remove_column :repositories, :importance
    remove_column :repositories, :transient_properties_id
  end
end
