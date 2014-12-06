class AddStateIndexes < ActiveRecord::Migration
  def up
    execute %[ALTER TABLE trials ADD CONSTRAINT valid_state CHECK 
      ( state IN (#{Constants::TRIAL_STATES.map{|s|"'#{s}'"}.join(', ')}));]
    add_index :trials, :state
  end

  def down
    remove_index :trials, :state
    execute %[ALTER TABLE trials DROP CONSTRAINT valid_state]
  end
end
