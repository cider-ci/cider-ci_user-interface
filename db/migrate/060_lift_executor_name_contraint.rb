class LiftExecutorNameContraint < ActiveRecord::Migration
  def change
    execute %q< ALTER TABLE executors DROP CONSTRAINT executors_name_constraints; >
  end
end
