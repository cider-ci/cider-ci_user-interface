#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TrialsController < WorkspaceController

  skip_before_action :require_sign_in,
                     only: [:show, :attachments]

  def show
    @trial = Trial.find params[:id]
    require_sign_in unless @trial.task.execution.public_view_permission?
    @scripts = @trial.scripts
  end

  def attachments
    @trial = Trial.find params[:id]
    require_sign_in unless @trial.task.execution.public_view_permission?
    @trial_attachments = @trial.trial_attachments.page(params[:page])
  end

  def result
    @trial = Trial.find params[:id]
  end

  def issues
    @trial = Trial.find(params[:id])
    @issues = @trial.trial_issues.page(params[:page])
  end

  def delete_issue
    TrialIssue.find(params[:issue_id]).destroy
    redirect_to issues_workspace_trial_path(params[:id])
  end

end
