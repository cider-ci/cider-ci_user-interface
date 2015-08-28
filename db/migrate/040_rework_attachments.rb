class ReworkAttachments < ActiveRecord::Migration

  class ::TreeAttachment < ActiveRecord::Base
  end

  class ::TrialAttachment < ActiveRecord::Base
  end

  def change

    remove_index :tree_attachments, :path

    add_column :tree_attachments, :tree_id, :text, limit: 40
    ::TreeAttachment.find_each do |ta|
      fields= ta.path.split('/').map(&:presence).compact
      ta.update_attributes! tree_id: fields.first,
        path:  fields[1..-1].join("/")
    end
    remove_column :tree_attachments, :to_be_retained_before
    change_column :tree_attachments, :tree_id, :text, limit: 40, null: false
    add_index :tree_attachments, :tree_id
    add_index :tree_attachments, [:tree_id, :path], unique: true

    execute "ALTER TABLE tree_attachments ADD CONSTRAINT check_tree_id CHECK (length(tree_id) = 40)"

    remove_index :trial_attachments, :path
    add_column :trial_attachments, :trial_id, :uuid
    TrialAttachment.find_each do |ta|
      fields= ta.path.split('/').map(&:presence).compact
      ta.update_attributes! trial_id: fields.first,
        path:  fields[1..-1].join("/")
    end
    remove_column :trial_attachments, :to_be_retained_before
    change_column :trial_attachments, :trial_id, :uuid, null: false
    add_index :trial_attachments, :trial_id
    add_index :trial_attachments, [:trial_id, :path], unique: true

  end
end
