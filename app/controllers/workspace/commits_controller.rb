#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::CommitsController < WorkspaceController
  include Workspace::CommitsControllerModules::CommitsFilter

  def index
    @commits = build_commits_for_params
    set_cache_signatures
  end

  def set_cache_signatures
    @commits_cache_signatures = \
      CommitCacheSignature.where(%< commit_id IN (?) >, @commits.map(&:id))
    @commits_cache_signatures_array =
      @commits_cache_signatures.map do |cs|
      [cs.commit_id, cs.branches_signature,
       cs.repositories_signature, cs.jobs_signature]
      end
  end

  def show
    @commit = Commit.find(params[:id])
  end

end
