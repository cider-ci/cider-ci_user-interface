class RemoveRadiatorConfig < ActiveRecord::Migration
  def change
    remove_column :welcome_page_settings, :radiator_config, :jsonb
  end
end
