class AdjustRemoteApiType < ActiveRecord::Migration
  def change

    execute <<-SQL
      ALTER TABLE repositories
        ALTER COLUMN remote_api_type DROP NOT NULL;

      ALTER TABLE repositories
        ALTER COLUMN remote_api_type SET DEFAULT NULL;
    SQL

    execute <<-SQL
      UPDATE repositories SET remote_api_type = NULL;
    SQL

  end
end
