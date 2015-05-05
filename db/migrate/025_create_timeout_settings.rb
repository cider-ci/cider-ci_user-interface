require Rails.root.join("db","migrate","migration_helper.rb")
class CreateTimeoutSettings < ActiveRecord::Migration
  include MigrationHelper
  def change
    create_table :timeout_settings, id: false  do |t|
      t.integer :id

      t.integer :trial_dispatch_timeout_minutes, default: 60, null: false
      t.integer :trial_end_state_timeout_minutes, default: 180, null: false
      t.integer :trial_job_timeout_minutes, default: 5, null: false

      t.integer :trial_scripts_retention_time_days, null: false, default: 10

    end

    add_auto_timestamps :timeout_settings

    execute "ALTER TABLE timeout_settings ADD PRIMARY KEY (id)"
    execute "ALTER TABLE timeout_settings ADD CONSTRAINT one_and_only_one CHECK (id = 0)"

    execute "ALTER TABLE timeout_settings ADD CONSTRAINT trial_dispatch_timeout_minutes_positive CHECK (trial_dispatch_timeout_minutes > 0)"
    execute "ALTER TABLE timeout_settings ADD CONSTRAINT trial_end_state_timeout_minutes_positive CHECK (trial_end_state_timeout_minutes > 0)"
    execute "ALTER TABLE timeout_settings ADD CONSTRAINT trial_job_timeout_minutes_positive CHECK (trial_job_timeout_minutes > 0)"

  end
end
