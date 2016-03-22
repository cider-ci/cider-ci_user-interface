class AddVersionToExecutors < ActiveRecord::Migration
  def change
    add_column :executors, :version, :text
  end
end
