class CompatibleSubmoduleIds < ActiveRecord::Migration
  def change
    change_column :submodules, :submodule_commit_id, :string, limit: 40
    change_column :submodules, :commit_id, :string, limit: 40
  end
end
