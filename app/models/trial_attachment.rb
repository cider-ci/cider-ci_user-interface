class TrialAttachment < ActiveRecord::Base
  include Concerns::UrlBuilder

  def url
    service_path(Settings[:services][:storage][:http]) \
      + "/trial-attachments/#{trial_id}/#{path}"
  end

  def path_id
    trial_id
  end

  default_scope { reorder(path: :asc) }

end
