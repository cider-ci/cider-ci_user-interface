class AddResultProperties < ActiveRecord::Migration
  def change
    %w(executions tasks trials).each do |table_name|
      add_column table_name, :result, :jsonb
    end
  end
end
