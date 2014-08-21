class TrialAttachment < ActiveRecord::Base
  def url
    Settings.storage_http_prefix + "/trial-attachments" + path
  end
end
