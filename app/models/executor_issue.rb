class ExecutorIssue < ApplicationRecord
  include Issue

  belongs_to :executor
end
