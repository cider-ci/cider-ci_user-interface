class AddCommitsDepthIndex < ActiveRecord::Migration
  def change
    add_index :commits, :depth
  end
end
