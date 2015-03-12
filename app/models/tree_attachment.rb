class TreeAttachment < ActiveRecord::Base
  include Concerns::UrlBuilder

  def url
    service_path(::Settings.services.storage.http) \
      + '/tree-attachments' + path
  end

  def tree_id
    path.split('/').second
  end

  default_scope { reorder(path: :asc) }

end
