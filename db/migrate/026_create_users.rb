require Rails.root.join("db","migrate","migration_helper.rb")
class CreateUsers < ActiveRecord::Migration
  include MigrationHelper

  def change
    create_table :users, id: :uuid do |t|
      t.string :password_digest

      t.string :login, null: false

      t.string :last_name, null: false, default: ''

      t.string :first_name, null: false, default: ''

      t.boolean :is_admin, null: false, default: false
    end

    add_auto_timestamps :users
    execute "CREATE INDEX user_lower_login_idx ON users(lower(login))"


    create_table :email_addresses, id: false do |t|
      t.uuid :user_id
      t.index :user_id
      t.string :email_address
      t.boolean :primary, default: false, null: false
    end
    execute "ALTER TABLE email_addresses ADD PRIMARY KEY (email_address)"

    add_foreign_key :email_addresses, :users, on_delete: :cascade


  end
end
