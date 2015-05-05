#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::JobsController < WorkspaceController

  include ::Workspace::JobsControllerModules::TasksFilter
  include ::Workspace::JobsControllerModules::JobsFilter
  include ::Workspace::JobsControllerModules::JobSelectionBuilder

  skip_before_action :require_sign_in,
                     only: [:show, :tree_attachments, :job_specification, :result]

  before_action do
    @_lookup_context.prefixes << 'workspace/commits'
    @_lookup_context.prefixes << 'workspace/tasks'
  end

  def build_create_request_data
    Job.new(params[:job].permit!).attributes \
      .select { |k, v| v.present? }.instance_eval { Hash[self] }
  end

  def request_create(data)
    url = service_base_url(::Settings.services.builder.http) + '/jobs/'

    RestClient::Request.new(
      method: :post,
      url: url,
      user: ::Settings.basic_auth.username,
      password: ::Settings.basic_auth.password,
      verify_ssl: false,
      payload: data.to_json,
      headers: { accept:  :json,
                 content_type:  :json })
  end

  def create
    begin
      resp = request_create(build_create_request_data).execute
      redirect_to workspace_job_path(JSON.parse(resp.body).deep_symbolize_keys[:id])
    rescue Exception => e
      @alerts[:errors] << Formatter.exception_to_s(e)
      render 'public/error', status: 500
    end
  end

  def destroy
    @job = Job.find params[:id]
    ActiveRecord::Base.transaction do
      @job.delete
    end
    redirect_to workspace_commits_path,
                flash: { successes: ["The job #{@job} has been deleted."] }
  end

  def edit
    @job = Job.find params[:id]
  end

  def index
    @link_params = params.slice(:branch, :page, :repository, :job_tags)
    @jobs = build_jobs_for_params
    @job_cache_signatures = JobCacheSignature \
      .where(%[ job_id IN (?)], @jobs.map(&:id))
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
      render 'public/error', status: 500
    end
  end

  def show
    @job = Job.select(:id, :state, :updated_at,
                      :name, :tree_id, :description, :result).find(params[:id])
    require_sign_in unless @job.public_view_permission?
    @link_params = params.slice(:branch, :page, :repository, :job_tags)
    @trials = Trial.joins(task: :job) \
      .where('jobs.id = ?', @job.id)
    set_and_filter_tasks params
    set_filter_params params
  end

  def issues
    @job = Job.find(params[:id])
    @issues = @job.job_issues.page(params[:page])
  end

  def delete_issue
    JobIssue.find(params[:issue_id]).destroy
    redirect_to issues_workspace_job_path(params[:id])
  end

  def job_specification
    @job = Job.find(params[:id])
    require_sign_in unless @job.public_view_permission?
  end

  def tree_attachments
    @job = Job.select(:id, :tree_id).find(params[:id])
    require_sign_in unless @job.public_view_permission?
    @tree_attachments = @job.tree_attachments.page(params[:page])
  end

  def retry_failed
    @job = Job.find params[:id]
    @job.tasks.where(state: 'failed').each do |task|
      Messaging.publish('task.create-trial', id: task.id)
    end
    set_filter_params params
    redirect_to workspace_job_path(@job, @filter_params),
                flash: { successes: ['The failed tasks are scheduled for retry!'] }
  end

  def update
    job = Job.find(params[:id])
    job.add_strings_as_tags param_tags
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

  def param_tags
    params[:job][:tags].split(',').select(&:present?)
  end

end
