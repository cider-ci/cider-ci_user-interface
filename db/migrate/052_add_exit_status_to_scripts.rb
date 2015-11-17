class AddExitStatusToScripts < ActiveRecord::Migration
  def change
    add_column :scripts, :exit_status, :integer
  end
end
