class AddDebugFieldsToScripts < ActiveRecord::Migration
  def change
    add_column :scripts, :command, :jsonb
    add_column :scripts, :working_dir, :string, limit: 2.kilobyte
    add_column :scripts, :script_file,  :string, limit: 2.kilobyte
    add_column :scripts, :wrapper_file,  :string, limit: 2.kilobyte
  end
end
