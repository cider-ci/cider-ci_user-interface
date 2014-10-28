class CreateTaskSpecs < ActiveRecord::Migration

  def change

    create_table :task_specs, id: :uuid do |t|
      t.json :data
    end

    add_column :tasks, :task_spec_id, :uuid

    add_foreign_key :tasks, :task_specs, dependent: :nullify


    reversible do |dir|

      dir.up do

        Task.where("data IS NOT NULL").find_in_batches do |tasks|
          tasks.each do |task|
            task.update_attributes! task_spec_id: TaskSpec.find_or_create_by_data!(task.data).id
          end
        end

      end

      dir.down do
      end

    end

    remove_column :tasks, :data, :json

  end


end
