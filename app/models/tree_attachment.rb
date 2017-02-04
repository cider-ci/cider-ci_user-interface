class TreeAttachment < ActiveRecord::Base
  include Concerns::UrlBuilder

  def url
    "#{service_path('/cider-ci/storage')}/tree-attachments/#{tree_id}/#{path}"
  end

  def path_id
    tree_id
  end

  default_scope { reorder(path: :asc) }

end
