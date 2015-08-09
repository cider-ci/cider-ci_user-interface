#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TasksController < WorkspaceController

  skip_before_action :require_sign_in, only: [:show]

  def retry
    set_task
    @job = @task.job
    if %(aborting aborted).include?  @job.state
      @job.update_attributes! state: 'pending'
    end
    existing_trial_ids = get_current_trial_ids
    Thread.new { Messaging.publish('task.create-trial', id: @task.id) }
    loop do
      sleep(0.1)
      Trial.connection.clear_query_cache
      break if existing_trial_ids != get_current_trial_ids
    end
    redirect_to workspace_trial_path(get_current_trial_ids.first),
      flash: { successes: ['A new trial is being executed'] }
  end

  def show
    set_task
    require_sign_in unless @task.job.public_view_permission?
  end

  def result
    set_task
  end

  def set_task
    @task = Task.find params[:id]
  end

  def get_current_trial_ids
    @task.reload.trials.reload.select(:id).map(&:id)
  end

end
