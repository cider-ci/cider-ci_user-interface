#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TasksController < WorkspaceController 

  skip_before_action :require_sign_in, only: [:show]

  def retry 
    begin
      @task = Task.find params[:id]
      Messaging.publish("task.create-trial", {id: @task.id})
      redirect_to workspace_execution_path(@task.execution), 
        flash: {success: "A new trial will be executed"}
    rescue Exception => e
      if @task.execution
        redirect_to workspace_execution_path(@task.execution), 
          flash: {error: Formatter.exception_to_s(e)}
      else
        redirect_to workspace_dashboard_path, 
          flash: {error: Formatter.exception_to_s(e)}
      end
    end
  end

  def show
    @task = Task.find params[:id]
    require_sign_in unless @task.execution.public_view_permission?
  end

end
