class DropViewDepths < ActiveRecord::Migration
  def up
    execute "DROP VIEW depths"
  end
end
