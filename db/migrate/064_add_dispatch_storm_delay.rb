class AddDispatchStormDelay < ActiveRecord::Migration
  def change
    add_column :tasks, :dispatch_storm_delay_seconds, :int, default: 1, null: false
    add_column :trials, :dispatched_at, :timestamp
  end
end
