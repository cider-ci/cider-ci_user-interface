#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::ExecutionsController < WorkspaceController

  include ::Workspace::ExecutionsControllerModules::TasksFilter
  include ::Workspace::ExecutionsControllerModules::ExecutionsFilter
  include ::Workspace::ExecutionsControllerModules::ExecutionSelectionBuilder

  skip_before_action :require_sign_in,
                     only: [:show, :tree_attachments, :specification]

  before_action do
    @_lookup_context.prefixes << 'workspace/commits'
    @_lookup_context.prefixes << 'workspace/tasks'
  end

  def build_create_request_data
    Execution.new(params[:execution].permit!).attributes \
      .select { |k, v| v.present? }.instance_eval { Hash[self] }
  end

  def request_create(data)
    url = service_base_url(::Settings.services.builder.http) + '/executions/'
    RestClient::Resource.new(
      url, ::Settings.basic_auth.username, ::Settings.basic_auth.password) \
      .post(Hash[data].to_json, content_type: :json)
  end

  def create
    begin
      resp = request_create(build_create_request_data)
      redirect_to workspace_execution_path(JSON.parse(resp).deep_symbolize_keys[:id])
    rescue Exception => e
      @alerts[:errors] << Formatter.exception_to_s(e)
      render 'public/error', status: 500
    end
  end

  def destroy
    @execution = Execution.find params[:id]
    ActiveRecord::Base.transaction do
      @execution.delete
    end
    redirect_to workspace_commits_path,
                flash: { successes: ["The execution #{@execution} has been deleted."] }
  end

  def edit
    @execution = Execution.find params[:id]
  end

  def index
    @link_params = params.slice(:branch, :page, :repository, :execution_tags)
    @executions = build_executions_for_params
    @execution_cache_signatures = ExecutionCacheSignature \
      .where(%[ execution_id IN (?)], @executions.map(&:id))
  end

  def new
    begin
      @commits = Commit.where(tree_id: params[:tree_id])
      set_creatable_executions params[:tree_id]
      if @creatable_executions.empty? and @alerts[:errors].empty?
        @alerts[:warnings] << "There are no executions available to be run.
      The desired execution might already exist
      or it was not defined in the first place.".squish
      end
    rescue Exception => e
      @alerts[:errors] << Formatter.exception_to_s(e)
      render 'public/error', status: 500
    end
  end

  def show
    @execution = Execution.select(:id, :state, :updated_at,
                                  :name, :tree_id, :description, :result).find(params[:id])
    require_sign_in unless @execution.public_view_permission?
    @link_params = params.slice(:branch, :page, :repository, :execution_tags)
    @trials = Trial.joins(task: :execution) \
      .where('executions.id = ?', @execution.id)
    set_and_filter_tasks params
    set_filter_params params
  end

  def issues
    @execution = Execution.find(params[:id])
    @issues = @execution.execution_issues.page(params[:page])
  end

  def delete_issue
    ExecutionIssue.find(params[:issue_id]).destroy
    redirect_to issues_workspace_execution_path(params[:id])
  end

  def specification
    @execution = Execution.find(params[:id])
    require_sign_in unless @execution.public_view_permission?
  end

  def tree_attachments
    @execution = Execution.select(:id, :tree_id).find(params[:id])
    require_sign_in unless @execution.public_view_permission?
    @tree_attachments = @execution.tree_attachments.page(params[:page])
  end

  def retry_failed
    @execution = Execution.find params[:id]
    @execution.tasks.where(state: 'failed').each do |task|
      Messaging.publish('task.create-trial', id: task.id)
    end
    set_filter_params params
    redirect_to workspace_execution_path(@execution, @filter_params),
                flash: { successes: ['The failed tasks are scheduled for retry!'] }
  end

  def update
    execution = Execution.find(params[:id])
    execution.add_strings_as_tags param_tags
    execution.update_attributes! params.require(:execution).permit(:priority)
    redirect_to workspace_execution_path(execution),
                flash: { successes: ['The execution has been updated.'] }
  end

  def set_filter_params(params)
    @filter_params = params.slice(:tasks_select_condition,
                                  :name_substring_term, :per_page)
  end

  def result
    @execution = Execution.find(params[:id])
  end

  def param_tags
    params[:execution][:tags].split(',').select(&:present?)
  end

end
