class TrialIssue < ActiveRecord::Base
  include Issue

  belongs_to :trial
end
