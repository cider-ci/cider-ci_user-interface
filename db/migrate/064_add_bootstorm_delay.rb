class AddBootstormDelay < ActiveRecord::Migration
  def change
    add_column :tasks, :bootstorm_delay_seconds, :int, default: 5, null: false
  end
end
