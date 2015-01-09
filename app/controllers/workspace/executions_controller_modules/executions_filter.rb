module Workspace::ExecutionsControllerModules::ExecutionsFilter
  extend ActiveSupport::Concern

  def build_executions_for_params
    filter_executions_for_tree_id filter_executions_for_tags filter_by_repository_names \
      filter_executions_for_branch_name set_per_page build_executions_initial_scope
  end

  def set_per_page(executions)
    if params[:per_page].present?
      executions.per(Integer(params[:per_page]))
    else
      executions
    end
  end

  def build_executions_initial_scope
    Execution.reorder(created_at: :desc).page(params[:page]) \
      .select(:id, :created_at, :tree_id, :state, :name, :updated_at)
  end

  def filter_executions_for_tree_id(executions)
    if tree_id_filter
      executions.where(tree_id: tree_id_filter)
    else
      executions
    end
  end

  def filter_by_repository_names(executions)
    unless repository_names_filter.empty?
      executions.joins(commits: { branches: :repository }) \
        .distinct.where(repositories: { name: repository_names_filter })
    else
      executions
    end
  end

  def filter_executions_for_branch_name(executions)
    unless branch_names_filter.empty?
      executions.joins(commits: :branches) \
        .where(branches: { name: branch_names_filter })
    else
      executions
    end
  end

  def filter_executions_for_tags(executions)
    if execution_tags_filter.count > 0
      executions.joins(:tags).where(tags: { tag: execution_tags_filter })
    else
      executions
    end
  end

end
