class TrialAttachment < ActiveRecord::Base
  include Concerns::UrlBuilder

  def url
    service_path('/cider-ci/storage') \
      + "/trial-attachments/#{trial_id}/#{path}"
  end

  def path_id
    trial_id
  end

  default_scope { reorder(path: :asc) }

end
