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
      headers: { accept: :json,
                 content_type: :json })
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

  def abort
    request_dispatcher_custom_action 'abort', 'Abort'
  end

  def request_dispatcher_custom_action(action, name = action)
    job = Job.find(params[:id])
    url = service_base_url(Settings.services.dispatcher.http) + "/jobs/#{job.id}/#{action}"
    response = http_do(:post, url)
    case response.status
    when 300..600
      redirect_to workspace_job_path(job.id),
                  flash: { errors: [" #{response.status} #{name}" \
                                    "request failed! #{response.body}"] }
    else
      redirect_to workspace_job_path(job.id, @filter_params),
                  flash: { successes:
                           ["#{response.status} #{name} " \
                            "request succeeded. #{response.body}"] }
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
    @job = Job.select(:id, :state, :updated_at,
                      :name, :tree_id, :description, :result).find(params[:id])
    require_sign_in unless @job.public_view_permission?
    @link_params = params.slice(:branch, :page, :repository, :job_tags)
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

  def retry_and_resume
    request_dispatcher_custom_action 'retry-and-resume', 'Retry and resume'
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
