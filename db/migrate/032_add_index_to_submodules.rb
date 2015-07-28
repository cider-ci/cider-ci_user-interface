class AddIndexToSubmodules < ActiveRecord::Migration
  def change
    add_index :submodules, :submodule_commit_id
  end
end
