class TreeAttachment < ActiveRecord::Base
  include Concerns::UrlBuilder

  def url
    service_base_url(::Settings.storage_service) + '/tree-attachments' + path
  end

  def tree_id
    path.split('/').second
  end

  default_scope { reorder(path: :asc) }

end
