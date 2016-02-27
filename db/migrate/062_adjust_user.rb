class AdjustUser < ActiveRecord::Migration
  def change
    add_column :users, :name, :string
    add_column :users, :github_access_token, :string
    add_column :users, :github_id, :integer
    add_column :users, :account_enabled, :boolean, null: false, default: true
    add_column :users, :password_sign_in_allowed, :boolean, null: false, default: true
    add_column :users, :max_session_lifetime, :string, default: '7 days'
    User.find_each.each do |user|
      user.update_attributes! name:
        "#{user.first_name} #{user.last_name}".squish.presence
    end
    remove_column :users, :first_name
    remove_column :users, :last_name
    #execute "DROP INDEX user_lower_login_idx"
    #execute "CREATE UNIQUE INDEX user_lower_login_idx ON users(lower(login))"
  end
end
