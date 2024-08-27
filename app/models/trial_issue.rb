class TrialIssue < ApplicationRecord
  include Issue

  belongs_to :trial
end
