class MigrateJsonToJsonb < ActiveRecord::Migration
  def up
    execute 'ALTER TABLE trials ALTER COLUMN scripts TYPE jsonb USING scripts::jsonb'
    execute 'ALTER TABLE specifications ALTER COLUMN data TYPE jsonb USING data::jsonb'
    execute 'ALTER TABLE task_specs ALTER COLUMN data TYPE jsonb USING data::jsonb'
  end
end
