class TreeAttachment < ActiveRecord::Base
  include Concerns::UrlBuilder

  def url
    service_base_url(::Settings.storage_service) + "/tree-attachments" + path
  end

end
