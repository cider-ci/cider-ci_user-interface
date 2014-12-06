#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module Constants 
  STATES= %w(
    aborted
    executing 
    failed 
    passed 
    pending
    ).sort
  EXECUTION_STATES= STATES
  TASK_STATES= STATES
  TRIAL_STATES= (Array.new(STATES) << "dispatching").sort

  UPDATE_BRANCH_TOPIC_NAME = '/topics/branch_updates'
end
