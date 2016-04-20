class TreeAttachment < ActiveRecord::Base
  include Concerns::UrlBuilder
  paginates_per 100 # kaminari

  def url
    "#{service_path(Settings[:services][:storage][:http])}/tree-attachments/#{tree_id}/#{path}"
  end

  def path_id
    tree_id
  end

  default_scope { reorder(path: :asc) }

end
