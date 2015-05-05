require Rails.root.join("db","migrate","migration_helper.rb")
class CreateTasks < ActiveRecord::Migration
  include MigrationHelper

  def change

    create_table :task_specifications, id: :uuid do |t|
      t.jsonb :data   
    end

    create_table :tasks, id: :uuid  do |t|

      t.uuid :job_id, null: false
      t.index :job_id

      t.string :state, null: false, default: 'pending'

      t.text :name, null: false
      t.index [:job_id,:name], unique: true

      t.jsonb :result

      t.uuid :task_specification_id, null: false
      t.index :task_specification_id

      t.integer :priority, null: false, default: 0

      t.string :traits, array: true, null: false, default: '{}'
      t.index :traits 

      t.text :error, null: false, default: ""

      t.string :exclusive_resources, array: true, null: false, default: '{}'
      t.index :exclusive_resources

    end

    add_auto_timestamps :tasks

    add_foreign_key :tasks, :jobs , name: "tasks_jobs_fkey", on_delete: :cascade

    reversible  do |dir|
      dir.up do
        execute %[ALTER TABLE tasks ADD CONSTRAINT check_tasks_valid_state CHECK 
          (state IN (#{Constants::TASK_STATES.map{|s|"'#{s}'"}.join(', ')}));]
      end
    end

  end
end
