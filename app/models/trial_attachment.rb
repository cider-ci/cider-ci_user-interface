class TrialAttachment < ActiveRecord::Base
  include Concerns::UrlBuilder

  def url
    service_base_url(::Settings.storage_service) + "/trial-attachments" + path
  end

  def trial_id
    path.split("/").second
  end

  default_scope { reorder(path: :asc) }

end
