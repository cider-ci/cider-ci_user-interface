module Concerns
  module CommitsFilter
    extend ActiveSupport::Concern

    def build_git_ref_filter(git_ref)
      lambda do |commits|
        if (not git_ref)
          commits
        elsif git_ref.length == 40
          commits.where('commits.id = :git_ref OR tree_id = :git_ref',
                        git_ref: git_ref)
        else
          commits.where('commits.id ilike :git_ref OR tree_id ilike :git_ref',
                        git_ref: (git_ref + '%'))
        end
      end
    end

    def build_text_search_filter(text_search)
      lambda do |commits|
        if text_search
          commits.basic_search(text_search, false)
        else
          commits
        end
      end
    end

    # this one doesn't do anything useful on its own; but it limits the search
    # space and makes the query quite a bit faster; it does so by evaluating the
    # query and moving the limit until the per page count is satisfied; therefore
    # it MUST be the last filter to be added
    def build_time_filter_for_query_performance
      lambda do |commits|
        days = 10
        while  (days < (365 * 100)) and (chain_days(commits, days) \
               .limit(2 * per_page_param).count('commits.id') <= per_page_param)
          days *= 10
        end
        chain_days(commits, days)
      end
    end

    def chain_days(commits, days)
      commits.where(
        %[ "commits"."committer_date"  > ( now() - interval '? days') ],
        days)
    end

    def build_commits_by_branches_names_filter(branch_names)
      lambda do |commits|
        unless branch_names.empty?
          commits.joins(:branches) \
            .where(branches: { name: branch_names })
        else
          commits
        end
      end
    end

    def build_commits_by_repository_name_filter(repository_names)
      lambda do |commits|
        unless repository_names.empty?
          commits.joins(branches: :repository) \
            .where(repositories: { name: repository_names })
        else
          commits
        end
      end
    end

    def build_commits_by_page_filter(per_page)
      lambda do |commits|
        if per_page.present?
          commits.per(Integer(per_page))
        else
          commits
        end
      end
    end

    def build_commits_by_depth_filter(depth)
      lambda do |commits|
        case depth
        when -1
          commits
        when 0
          commits.joins(:head_of_branches)
        else
          # TODO: there should be a way to formulate this without recursion;
          # something like exists commit which is not to far away from the
          # head; if this succeeds remove the time filter hack
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
    end

  end
end
