require Rails.root.join("db","migrate","migration_helper.rb")
class CreateTrials < ActiveRecord::Migration
  include MigrationHelper

  def change

    create_table :trials, id: :uuid do |t|

      t.uuid :task_id, null: false
      t.index :task_id

      t.uuid :executor_id

      t.text :error

      t.string :state, null: false, default: 'pending'
      t.index :state

      t.jsonb :scripts

      t.jsonb :result

      t.timestamp :started_at
      t.timestamp :finished_at

    end

    add_auto_timestamps :trials

    add_foreign_key :trials, :tasks, name: "trials_tasks_fkey", on_delete: :cascade

    execute %[ALTER TABLE trials ADD CONSTRAINT valid_state CHECK
      ( state IN (#{Settings.constants.STATES.TRIAL.map{|s|"'#{s}'"}.join(', ')}));]

  end

end
