#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TasksController < WorkspaceController

  skip_before_action :require_sign_in, only: [:show]

  def retry
    set_task
    Messaging.publish('task.create-trial', id: @task.id)
    redirect_to workspace_job_path(@task.job),
                flash: { successes: ['A new trial will be executed'] }
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

end
