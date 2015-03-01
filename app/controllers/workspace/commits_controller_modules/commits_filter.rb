module Workspace::CommitsControllerModules::CommitsFilter
  extend ActiveSupport::Concern

  def build_commits_for_params
    filter_by_time \
      filter_by_text \
        filter_by_respository \
          filter_by_branches \
            filter_by_show_orphans \
              per_page \
                commits_initial_scope
  end

  def commits_initial_scope
    Commit.distinct.page(params[:page]) \
      .reorder(committer_date: :desc, depth: :desc) \
      .select(:committer_date, :committer_name,
              :depth, :id, :subject, :tree_id, :updated_at)
  end

  def per_page(commits)
    if params[:per_page].present?
      commits.per(Integer(params[:per_page]))
    else
      commits
    end
  end

  def filter_by_show_orphans(commits)
    unless params[:show_orphans].present?
      commits.joins(:branches)
    else
      commits
    end
  end

  def filter_by_branches(commits)
    unless branch_names_filter.empty?
      commits.joins(:branches) \
        .where(branches: { name: branch_names_filter })
    else
      commits
    end
  end

  def filter_by_respository(commits)
    unless repository_names_filter.empty?
      commits.joins(branches: :repository) \
        .where(repositories: { name: repository_names_filter })
    else
      commits
    end
  end

  def filter_by_text(commits)
    if commit_text_search_filter
      commits.basic_search(commit_text_search_filter, false)
    else
      commits
    end
  end

  def filter_by_time(commits)
    commits.where(
      %[ "commits"."committer_date"  > ( now() - interval '? days') ],
      commited_within_last_days_filter)
  end

end
