class SetPasswordsIfBlank < ActiveRecord::Migration
  def change
    User.find_each do |user|
      user.create_password_if_blank
    end
  end
end
