class TreeAttachment < ActiveRecord::Base
  def url
    Settings.storage_http_prefix + "/tree-attachments" + path
  end
end
