#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::CommitsController < WorkspaceController

  def index
    @commits = Commit.distinct.page(params[:page])

    @commits = @commits.per(Integer(params[:per_page])) unless params[:per_page].blank?

    filter_by_branches_and_repository

    filter_by_text_and_time

    set_order_and_select

    set_cache_signatures
  end

  def filter_by_branches_and_repository
    unless branch_names_filter.empty?
      @commits = @commits.joins(:branches) \
        .where(branches: { name: branch_names_filter })
    end

    unless repository_names_filter.empty?
      @commits = @commits.joins(branches: :repository) \
        .where(repositories: { name: repository_names_filter })
    end
  end

  def filter_by_text_and_time
    if commit_text_search_filter
      @commits = @commits.basic_search(commit_text_search_filter, false)
    end

    if commited_within_last_days_filter
      @commits = @commits \
        .where(%[ "commits"."committer_date"  > ( now() - interval '? days') ],
               commited_within_last_days_filter)
    end
  end

  def set_order_and_select
    @commits = @commits.reorder(committer_date: :desc, depth: :desc)
    @commits = @commits.select(:committer_date, :committer_name,
                               :depth, :id, :subject, :tree_id, :updated_at)
  end

  def set_cache_signatures
    @commits_cache_signatures = \
      CommitCacheSignature.where(%< commit_id IN (?) >, @commits.map(&:id))
    @commits_cache_signatures_array =
      @commits_cache_signatures.map do |cs|
      [cs.commit_id, cs.branches_signature,
       cs.repositories_signature, cs.executions_signature]
      end
  end

end
