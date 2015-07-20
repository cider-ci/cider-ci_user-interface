module Workspace::CommitsControllerModules::CommitsFilter
  extend ActiveSupport::Concern

  def build_commits_for_params
    filter_by_time \
      filter_by_text \
        filter_by_respository \
          filter_by_branches \
            filter_by_depth \
              filter_per_page \
                commits_initial_scope
  end

  def commits_initial_scope
    Commit.distinct.page(params[:page]) \
      .reorder(committer_date: :desc, depth: :desc) \
      .select(:committer_date, :committer_name,
              :depth, :id, :subject, :tree_id, :updated_at)
  end

  def filter_per_page(commits)
    if params[:per_page].present?
      commits.per(Integer(params[:per_page]))
    else
      commits
    end
  end

  def filter_by_depth(commits)
    depth = Integer(params[:depth]) rescue 0
    case depth
    when -1
      commits
    when 0
      commits.joins(:head_of_branches)
    else
      commits.joins(:branches) \
        .joins('JOIN commits AS heads ON branches.current_commit_id = heads.id') \
        .where("commits.id IN (
                  WITH RECURSIVE close_commits(id,depth) AS (
                    SELECT c0.id, 0 FROM commits c0 WHERE id = heads.id
                  UNION
                    SELECT c0.id, close_commits.depth + 1 FROM commits c0, close_commits
                    JOIN commit_arcs ON commit_arcs.child_id = close_commits.id
                    WHERE c0.id = commit_arcs.parent_id
                    AND close_commits.depth < ?
               )
               SELECT close_commits.id FROM close_commits
               )", depth)
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
    days = 10
    while  days < (365 * 100) and \
      chain_days(commits, days).limit(2 * per_page).count('commits.id') <= per_page
      days *= 10
    end
    chain_days(commits, days)
  end

  def chain_days(commits, days)
    commits.where(
      %[ "commits"."committer_date"  > ( now() - interval '? days') ],
      days)
  end

  def per_page
    Integer(params[:per_page]) rescue Kaminari.config.default_per_page
  end

end
