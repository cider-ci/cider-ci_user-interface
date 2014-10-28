class TrialScriptsArrayToMap < ActiveRecord::Migration
  def change
    remove_column :trials,:scripts,:json
    add_column :trials,:scripts,:json
  end
end
