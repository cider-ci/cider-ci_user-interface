class DropBranchUpdateTriggers < ActiveRecord::Migration
  def change
    execute "DROP TABLE branch_update_triggers CASCADE"
  end
end
