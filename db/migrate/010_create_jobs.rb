require Rails.root.join("db","migrate","migration_helper.rb")
class CreateJobs < ActiveRecord::Migration
  include MigrationHelper

  def change

    create_table :job_specifications, id: :uuid do |t|
      t.jsonb :data
    end

    create_table :jobs, id: :uuid  do |t|
      t.string :state, null: false, default: 'pending'

      t.text :key, null: false
      t.index :key

      t.text :name, null: false
      t.index :name

      t.text :description

      t.jsonb :result

      t.string :tree_id, null: false, limit: 40
      t.index :tree_id

      t.uuid :job_specification_id, null: false
      t.index :job_specification_id

      t.integer :priority, null: false, default: 0

      t.index [:tree_id,:key], unique: true,
        name: 'idx_jobs_tree-id_key'

      t.index [:tree_id,:name], unique: true,
        name: 'idx_jobs_tree-id_name'

      t.index [:tree_id,:job_specification_id], unique: true,
        name: 'idx_jobs_tree-id_job-specification-id'

    end
    add_auto_timestamps :jobs

    add_foreign_key :jobs, :job_specifications, name: "jobs_job-specifications_fkey"

    reversible  do |dir|
      dir.up do
        execute %[ALTER TABLE jobs ADD CONSTRAINT check_jobs_valid_state CHECK
          (state IN (#{Settings[:constants][:STATES][:JOB].map{|s|"'#{s}'"}.join(', ')}));]
      end
    end

  end
end
