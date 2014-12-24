#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::ExecutionsController < WorkspaceController

  include ::Workspace::ExecutionsController::TasksFilter

  skip_before_action :require_sign_in,
                     only: [:show, :tree_attachments, :specification]

  before_action do
    @_lookup_context.prefixes << 'workspace/commits'
    @_lookup_context.prefixes << 'workspace/tasks'
  end

  def create
    Fun.wrap_exception_with_redirect(self, :back) do
      create_execution
      @execution.create_tasks_and_trials
      branches = @commit.head_of_branches
      @execution.add_strings_as_tags [branches.map(&:name),
                                      branches.map(&:repository).map(&:name),
                                      @current_user.try(:login) || ''].flatten
      redirect_to workspace_execution_path(@execution),
                  flash: { successes: ["The execution has been created.
                        Tasks and trials will be created in the background."] }
    end
  end

  def create_execution
    ActiveRecord::Base.transaction do
      @commit = Commit.find params[:commit_id]
      @definition = Definition.find(params[:definition_id])
      create_map = \
        { specification: @definition.specification,
          name: @definition.name,
          tree_id: @commit.tree_id }.merge(
           params.require(:execution).permit(:priority))
      @execution = Execution.create! create_map
      @execution.add_strings_as_tags params[:execution][:tags].split(',')
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

    @executions = Execution.reorder(created_at: :desc).page(params[:page])

    @executions = @executions.joins(commits: :branches) \
      .where(branches: { name: branch_names_filter }) \
      unless branch_names_filter.empty?

    @executions = @executions.joins(commits: { branches: :repository }) \
      .distinct.where(repositories: { name: repository_names_filter }) \
      unless repository_names_filter.empty?

    @executions = @executions.per(Integer(params[:per_page])) \
      unless params[:per_page].blank?

    @executions = @executions.joins(:tags) \
      .where(tags: { tag: execution_tags_filter }) \
      if execution_tags_filter.count > 0

    @executions = @executions.select(:id, :created_at, :tree_id,
                                     :state, :name, :updated_at)

    @execution_cache_signatures = ExecutionCacheSignature \
      .where(%[ execution_id IN (?)], @executions.map(&:id))
  end

  def new
    @execution = Execution.new
    @commit = Commit.find params[:commit_id]
    @definitions = Definition.all
  end

  def show
    @execution = Execution.select(:id, :state, :updated_at,
                                  :name, :tree_id).find(params[:id])
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
    @execution = Execution.find(params[:id])
    @execution.tags = params[:execution][:tags] \
      .split(',').map(&:strip).reject(&:blank?) \
      .map { |s| Tag.find_or_create_by(tag: s) }
    @execution.update_attributes! params.require(:execution).permit(:priority)
    redirect_to workspace_execution_path(@execution),
                flash: { successes: ['The execution has been updated.'] }
  end

  def set_filter_params(params)
    @filter_params = params.slice(:tasks_select_condition,
                                  :name_substring_term, :per_page)
  end

end
