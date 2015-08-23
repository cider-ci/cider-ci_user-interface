class AddFkeyTrialAttachmentsTrials < ActiveRecord::Migration
  def change
    add_foreign_key :trial_attachments, :trials, on_delete: :cascade
  end
end
