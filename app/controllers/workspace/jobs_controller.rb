#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::JobsController < WorkspaceController

  include ::Workspace::JobsControllerModules::TasksFilter
  include ::Workspace::JobsControllerModules::JobsFilter
  include ::Workspace::JobsControllerModules::JobSelectionBuilder

  include ::Concerns::HTTP
  include ::Concerns::UrlBuilder

  skip_before_action :require_sign_in,
    only: [:show, :tree_attachments, :job_specification, :result]

  before_action do
    @_lookup_context.prefixes << 'workspace/commits'
    @_lookup_context.prefixes << 'workspace/tasks'
  end

  def create
    url = service_base_url(Settings[:services][:builder][:http]) + '/jobs/'
    response = http_do(:post, url) do |c|
      c.headers['content-type'] = 'application/json'
      c.body = params[:job].slice(:key, :tree_id) \
        .merge(created_by: current_user.id).to_json
    end
    case response.status
    when 300..600
      redirect_to workspace_path,
        flash: { errors: [
          "The creation of a new job failed: #{response.status} #{response.body}"] }
    else
      redirect_to workspace_job_path(JSON.parse(response.body).deep_symbolize_keys[:id]),
        flash: { successes: [
          "#{response.status} A new job has been created. "] }
    end
  end

  def abort
    job = Job.find(params[:id])
    url = service_base_url(Settings[:services][:dispatcher][:http]) + "/jobs/#{job.id}/abort"
    response = http_do(:post, url) do |c|
      c.headers['content-type'] = 'application/json'
      c.body = { aborted_by: current_user.id,
                 aborted_at: Time.now.iso8601(4) }.to_json
    end
    case response.status
    when 300..600
      redirect_to workspace_job_path(job.id),
        flash: { errors: ["Abort failed: #{response.status} #{response.body}"] }
    else
      redirect_to workspace_job_path(job.id, @filter_params),
        flash: { successes: ["#{response.status} Aborted! "] }
    end
  end

  def edit
    @job = Job.find params[:id]
  end

  def new
    begin
      @commits = Commit.where(tree_id: params[:tree_id])
      set_runnable_jobs params[:tree_id]
      if @runnable_jobs.empty? and @alerts[:errors].empty?
        @alerts[:warnings] << "There are no jobs available to be run.
      The desired job might already exist
      or it was not defined in the first place.".squish
      end
    rescue Exception => e
      @alerts[:errors] << Formatter.exception_to_s(e)
      render 'available_jobs_error', status: 500
    end
  end

  def show
    @job = Job.find(params[:id])
    require_sign_in unless @job.public_view_permission?
    @link_params = params.slice(:branch, :page, :repository)
    @trials = Trial.joins(task: :job).where('jobs.id = ?', @job.id)
    set_and_filter_tasks params
    set_filter_params params
  end

  def issues
    @job = Job.find(params[:id])
    @issues = @job.job_issues.page(params[:page])
  end

  def delete_issue
    JobIssue.find(params[:issue_id]).destroy
    redirect_to workspace_job_path(params[:id])
  end

  def job_specification
    @job = Job.find(params[:id])
    require_sign_in unless @job.public_view_permission?
    respond_to do |format|
      format.html
      format.json do
        render json: JSON.pretty_generate(@job.job_specification.data)
      end
      format.yaml do
        render content_type: 'text/yaml', body: @job.job_specification.data.to_yaml
      end
    end
  end

  def tree_attachments
    @job = Job.select(:id, :tree_id).find(params[:id])
    require_sign_in unless @job.public_view_permission?
    @tree_attachments = @job.tree_attachments.page(params[:page])
  end

  def retry_and_resume
    job = Job.find(params[:id])
    url = service_base_url(Settings[:services][:dispatcher][:http]) \
      + "/jobs/#{job.id}/retry-and-resume"
    response = http_do(:post, url) do |c|
      c.headers['content-type'] = 'application/json'
      c.body = { resumed_by: current_user.id,
                 resumed_at: Time.now.iso8601(4) }.to_json
    end
    case response.status
    when 300..600
      redirect_to workspace_job_path(job.id),
        flash: { errors: [
          "Retry and resume retry failed: #{response.status} #{response.body}"] }
    else
      redirect_to workspace_job_path(job.id, @filter_params),
        flash: { successes: ["#{response.status}  Retrying and resuming! "] }
    end
  end

  def update
    job = Job.find(params[:id])
    job.update_attributes! params.require(:job).permit(:priority)
    redirect_to workspace_job_path(job),
      flash: { successes: ['The job has been updated.'] }
  end

  def set_filter_params(params)
    @filter_params = params.slice(:tasks_select_condition,
      :name_substring_term, :per_page)
  end

  def result
    @job = Job.find(params[:id])
  end

end
