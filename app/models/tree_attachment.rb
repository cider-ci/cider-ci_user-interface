class TreeAttachment < ActiveRecord::Base
  include Concerns::UrlBuilder

  def url
    service_base_url(::Settings.services.storage.http_external, omit_protocol: true) \
      + '/tree-attachments' + path
  end

  def tree_id
    path.split('/').second
  end

  default_scope { reorder(path: :asc) }

end
