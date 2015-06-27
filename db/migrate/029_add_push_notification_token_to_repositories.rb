class AddPushNotificationTokenToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :update_notification_token, :uuid, default: 'uuid_generate_v4()'
    add_index :repositories, :update_notification_token
  end
end
