class AddUserSettings < ActiveRecord::Migration
  def change
    add_column :users, :mini_profiler_is_enabled, :boolean, default: false
    add_column :users, :reload_frequency, :string
    add_column :users, :ui_theme, :string
  end
end
