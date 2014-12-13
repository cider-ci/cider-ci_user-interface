#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module Constants 
  # keep order (because of execution stats/progress)
  STATES= %w(
    failed 
    aborted
    pending
    executing 
    passed 
    )
  EXECUTION_STATES= STATES
  TASK_STATES= STATES
  TRIAL_STATES= (Array.new(STATES).insert 3, "dispatching")

  UPDATE_BRANCH_TOPIC_NAME = '/topics/branch_updates'
end
