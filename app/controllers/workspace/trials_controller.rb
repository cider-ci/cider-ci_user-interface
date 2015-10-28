#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TrialsController < WorkspaceController

  include ::Workspace::Trials::ScriptDependencyGraph

  skip_before_action :require_sign_in,
    only: [:show, :attachments]

  def show
    begin
      @trial = Trial.find params[:id]
      require_sign_in unless @trial.task.job.public_view_permission?
      @scripts = @trial.scripts.map { |k, v| { 'name' => k }.merge(v) } \
        .sort_by { |s| script_order(s) }
    rescue StandardError => e
      Rails.logger.warn(e)
      render 'show_raw'
    end
  end

  def attachments
    @trial = Trial.find params[:id]
    require_sign_in unless @trial.task.job.public_view_permission?
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

  def scripts_gantt_chart
  end

  def scripts_dependency_graph
  end

  def scripts_start_dependency_graph
  end

  def scripts_terminate_dependency_graph
  end

  private

  def script_order(s)
    begin
      Time.iso8601(s['started_at'] || s['skipped_at']).iso8601
    rescue Exception => _
      s['name'] || '0'
    end
  end

end
