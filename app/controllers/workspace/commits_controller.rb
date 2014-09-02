#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::CommitsController < WorkspaceController 

  def index
    @link_params = params.slice(:branch,:commit,:page,:per_page,:repository,:commited_within_last_days)

    @commits = Commit.distinct.page(params[:page])
    @commits= @commits.per(Integer(params[:per_page])) unless params[:per_page].blank?

    @commits = @commits.joins(:branches) \
      .where(branches:{name: branch_names_filter}) unless branch_names_filter.empty?

    @commits = @commits.joins(branches: :repository) \
      .where(repositories: {name: repository_names_filter}) unless repository_names_filter.empty?

    @commits = @commits.basic_search(commit_text_search_filter,false) if commit_text_search_filter


    if commited_within_last_days_filter
      @commits= @commits \
        .where(%[ "commits"."committer_date"  > ( now() - interval '? days') ], 
               commited_within_last_days_filter) 
    end

    @commits = @commits.reorder(committer_date: :desc, depth: :desc)

    @commits= @commits.select(:committer_date,:committer_name,:depth,:id,:subject,:tree_id,:updated_at)

    @commits_cache_signatures = CommitCacheSignature.where(%< commit_id IN (?) >, @commits.map(&:id) )

    @commits_cache_signatures_array= @commits_cache_signatures.map do |cs| 
      [cs.commit_id,cs.branches_signature,cs.repositories_signature,cs.executions_signature]
    end

  end

  def show
    @commit = Commit.find params[:id]
  end

end

