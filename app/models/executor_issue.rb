class ExecutorIssue < ActiveRecord::Base
  include Issue

  belongs_to :executor

end
