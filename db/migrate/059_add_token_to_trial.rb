class AddTokenToTrial < ActiveRecord::Migration
  def change
    add_column :repositories, :proxy_id, :uuid, null: false, default: 'uuid_generate_v4()'
    add_column :trials, :token, :uuid, null: false, default: 'uuid_generate_v4()'
    reversible do |dir|
      dir.up do
        execute "ALTER TABLE repositories ALTER COLUMN proxy_id SET NOT NULL"
        execute "ALTER TABLE trials ALTER COLUMN token SET NOT NULL"
      end
    end
  end
end
