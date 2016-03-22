class ScriptIssues < ActiveRecord::Migration
  def change
    remove_column :scripts, :error, :text
    add_column :scripts, :issues, :jsonb, default: '{}', null: false, index: true
    add_index :scripts, :issues
  end
end
