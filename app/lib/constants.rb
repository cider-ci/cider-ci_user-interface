#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module Constants
  # keep order (because of job stats/progress)
  STATES = %w(
    failed
    aborted
    skipped
    pending
    executing
    passed
  )
  JOB_STATES = STATES
  TASK_STATES = STATES
  TRIAL_STATES = (Array.new(STATES).insert 4, 'dispatching')

  UPDATE_BRANCH_TOPIC_NAME = '/topics/branch_updates'
end
