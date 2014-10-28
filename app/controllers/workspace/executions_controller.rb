#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::ExecutionsController < WorkspaceController 

  before_action do
    @_lookup_context.prefixes<< "workspace/commits"
    @_lookup_context.prefixes<< "workspace/tasks"
  end


  def create
    Fun.wrap_exception_with_redirect(self,:back) do 
      ActiveRecord::Base.transaction do
        @commit = Commit.find params[:commit_id]
        @definition = Definition.find(params[:definition_id])
        create_map = \
          {specification: @definition.specification, 
           name: @definition.name,
           tree_id: @commit.tree_id}.merge(params.require(:execution).permit(:priority))
        @execution = Execution.create! create_map
        @execution.add_strings_as_tags params[:execution][:tags].split(",") 
      end
      @execution.create_tasks_and_trials
      branches = @commit.head_of_branches
      @execution.add_strings_as_tags [branches.map(&:name),
                                      branches.map(&:repository).map(&:name), 
                                      @current_user.try(:login) || ""].flatten
      redirect_to workspace_execution_path(@execution), 
        flash: {success: "The execution has been created. 
              Tasks and trials will be created in the background."}
    end
  end


  def destroy
    @execution = Execution.find params[:id]
    begin
      ActiveRecord::Base.transaction do
        @execution.delete
      end
      redirect_to workspace_commits_path, flash: {success: "The execution #{@execution} has been destroyed."}
    rescue Exception => e
      path =  if @execution and not @execution.destroyed?
                workspace_execution_path(@execution) 
              else
                workspace_dashboard_path
              end
      redirect_to path , flash: {error: Formatter.exception_to_s(e)}
    end
  end

  def edit
    @execution = Execution.find params[:id]
  end

  def index
    @link_params = params.slice(:branch,:page,:repository,:execution_tags)
    @executions = Execution.reorder(created_at: :desc).page(params[:page])
    @executions= @executions.joins({commits: :branches}) \
      .where(branches:{name: branch_names_filter}) unless branch_names_filter.empty?
    @executions= @executions.joins({commits: {branches: :repository}}).distinct \
      .where(repositories: {name: repository_names_filter}) unless repository_names_filter.empty?
    @executions= @executions.per(Integer(params[:per_page])) unless params[:per_page].blank?
    @executions= @executions.joins(:tags).where(tags: {tag: execution_tags_filter}) if execution_tags_filter.count > 0

    @executions = @executions.select(:id,:created_at,:tree_id,:state,:name,:updated_at)

    @execution_cache_signatures = ExecutionCacheSignature \
      .where(%[ execution_id IN (?)], @executions.map(&:id))

  end

  def new
    @execution = Execution.new
    @commit = Commit.find params[:commit_id]
    @branches = Branch.where(current_commit_id: @commit.with_descendants.pluck(:id))
    @definitions = Definition.all
  end

  def show
    @link_params = params.slice(:branch,:page,:repository,:execution_tags)
    @execution = Execution.select(:id,:state,:updated_at,:name,:tree_id).find(params[:id])
    @trials= Trial.joins(task: :execution).where("executions.id = ?",@execution.id)
    set_and_filter_tasks params
    set_filter_params params
  end

  def issues
    @execution= Execution.find(params[:id])
    @issues = @execution.execution_issues.page(params[:page])
  end

  def delete_issue
    ExecutionIssue.find(params[:issue_id]).destroy
    redirect_to issues_workspace_execution_path(params[:id])
  end

  def specification
    @execution= Execution.find(params[:id])
  end

  def tree_attachments 
    @execution = Execution.select(:id,:tree_id).find(params[:id])
    @tree_attachments= @execution.tree_attachments.page(params[:page])
  end

  def retry_failed
    @execution = Execution.find params[:id]
    @execution.tasks.where(state: 'failed').each do |task|
      Messaging.publish("task.create-trial", {id: task.id})
    end
    set_filter_params params
    redirect_to workspace_execution_path(@execution,@filter_params), flash: {success: "The failed tasks are scheduled for retry!"}
  end

  def update
    begin 
      @execution = Execution.find(params[:id])
      @execution.tags= params[:execution][:tags] \
        .split(",").map(&:strip).reject(&:blank?) \
        .map{|s| Tag.find_or_create_by(tag: s)}
      @execution.update_attributes! params.require(:execution).permit(:priority)
      redirect_to workspace_execution_path(@execution), flash: {success: "The execution has been updated."}
    rescue Exception => e
      redirect_to edit_workspace_execution_path(@execution), flash: {error: e}
    end
  end


  def set_filter_params params
    @filter_params= params.slice(:tasks_select_condition,:name_substring_term,:per_page)
  end



  def set_and_filter_tasks params
    @tasks_select_condition = (params[:tasks_select_condition] || :with_unsucessful_trials).to_sym
    @name_substring_term= (params[:name_substring_term] || '')
    @page=params[:page]
    @tasks = @execution.tasks
    @tasks = case @tasks_select_condition
             when :with_unsucessful_trials
               @tasks.with_unsucessful_trials
             when :failed
               @tasks.where(state: 'failed')
             when :all
               @tasks
             else
               raise "unsupported select condition"
             end
    @tasks = if @name_substring_term.blank?
               @tasks
             else
               terms= @name_substring_term.split(/\s+OR\s+/)
               ilike_where= terms.map{" tasks.name ILIKE ? "}.join(" OR ")
               terms_matchers= terms.map{|term|  "%#{term}%"}
               args=[ilike_where,terms_matchers].flatten
               @tasks.where(*args)
             end
    @tasks= @tasks.reorder(:name).page(params[:page])
    @tasks= @tasks.per(Integer(params[:per_page])) unless params[:per_page].blank?
  end

end
