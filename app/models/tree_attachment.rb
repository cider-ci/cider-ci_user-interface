class TreeAttachment < ActiveRecord::Base
  include Concerns::UrlBuilder

  def url
    "#{service_path(Settings[:services][:storage][:http])}/tree-attachments/#{tree_id}/#{path}"
  end

  def path_id
    tree_id
  end

  default_scope { reorder(path: :asc) }

end
