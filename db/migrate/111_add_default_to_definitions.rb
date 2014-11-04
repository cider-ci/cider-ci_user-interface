class AddDefaultToDefinitions < ActiveRecord::Migration
  def change
    add_column :definitions, :is_default, :boolean, null: false, default: false
  end
end
