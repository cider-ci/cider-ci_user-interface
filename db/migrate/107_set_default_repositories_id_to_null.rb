class SetDefaultRepositoriesIdToNull < ActiveRecord::Migration
  def change
    execute "ALTER TABLE repositories ALTER  id SET DEFAULT NULL"
  end
end
