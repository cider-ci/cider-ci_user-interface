class AddUserIdToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :created_by, :uuid
    add_foreign_key :jobs, :users, column: :created_by

    add_column :jobs, :aborted_by, :uuid
    add_foreign_key :jobs, :users, column: :aborted_by
    add_column :jobs, :aborted_at, :timestamp

    add_column :jobs, :resumed_by, :uuid
    add_foreign_key :jobs, :users, column: :resumed_by
    add_column :jobs, :resumed_at, :timestamp


    add_column :trials, :created_by, :uuid
    add_foreign_key :trials, :users, column: :created_by

    add_column :trials, :aborted_by, :uuid
    add_foreign_key :trials, :users, column: :aborted_by
    add_column :trials, :aborted_at, :timestamp

  end
end
