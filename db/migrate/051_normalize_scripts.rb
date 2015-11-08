require Rails.root.join("db","migrate","migration_helper.rb")
class NormalizeScripts < ActiveRecord::Migration

  class ::Job < ActiveRecord::Base
    has_many :tasks
  end

  class ::Task < ActiveRecord::Base
    has_many :trials
  end

  class ::Trial < ActiveRecord::Base
  end

  class ::Script < ActiveRecord::Base
    belongs_to :trial
  end

  include MigrationHelper

  def change

    create_table :scripts, id: :uuid do |t|
      t.uuid :trial_id, null: false
      t.string :key, null: false
      t.string :state, null: false, default: 'pending'
      t.string :name, null: false
      t.string :stdout, limit: 10.megabyte, default: '', null: false
      t.string :stderr, limit: 10.megabyte, default: '', null: false
      t.string :body, limit: 10.kilobytes, default: '', null: false
      t.string :error, limit: 1.megabyte
      t.string :timeout
      t.string :exclusive_executor_resource
      t.timestamp :started_at
      t.timestamp :finished_at
      t.jsonb :start_when, default: '[]', null: false
      t.jsonb :terminate_when, default: '[]', null: false
      t.jsonb :environment_variables, default: '{}', null: false
      t.boolean :ignore_abort, default: false, null: false
      t.boolean :ignore_state, default: false, null: false
      t.boolean :template_environment_variables, default: false, null: false
    end

    add_auto_timestamps :scripts
    add_foreign_key :scripts, :trials, on_delete: :cascade

    execute %[
      ALTER TABLE scripts ADD CONSTRAINT check_trials_valid_state CHECK
      ( state IN (#{Settings.constants.STATES.SCRIPT.map{|s|"'#{s}'"}.join(', ')}));]


    def new_state old_state
      if old_state == 'waiting'
        'pending'
      elsif (Settings.constants.STATES.SCRIPT.include? old_state )
        old_state
      else
        'skipped'
      end
    end

    Trial.all.each do |trial|
      trial.scripts.with_indifferent_access.map{ |k,v|
        (v && v.merge(key: (v[:key] || k || v[:name]), name: (v[:name] || v[:key] || k))) \
          || k.merge(key: (k[:key] || k[:name]), name: (k[:name] || k[:key]))
      }.map{|s| s.map{|k,v| [k.underscore, v]}.instance_eval{ Hash[self]}}.each {|s|
        begin
          attrs= s.slice(*Script.attribute_names)
            .merge(finished_at: s[:finished_at] || s[:skipped_at] || s[:aborted_at])
            .merge(trial_id: trial.id).select{|k,v| v}.instance_eval{ Hash[self]}
            .merge(state: new_state(s['state']))
            .merge(error: [s['error'].presence, s['errors'].presence].flatten.compact.join("\n"))
            .merge(template_environment_variables:  (s['environment-variables_process-templates'].present? || false))
          Script.create! attrs
        rescue Exception => e
          Rails.logger.error e
        end
      }
    end
    add_index :scripts, [:trial_id, :key], unique: true
    remove_column :trials, :scripts

    ###########################################################################

  end
end
