class DropViewDepths < ActiveRecord::Migration
  def up
    execute "DROP VIEW IF EXISTS depths"
  end
end
