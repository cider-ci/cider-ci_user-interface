module Concerns
  module CommitsFilter
    extend ActiveSupport::Concern

    def build_git_ref_filter(git_ref)
      lambda do |commits|
        if !git_ref
          commits
        elsif git_ref.length == 40
          commits.where("commits.id = :git_ref OR tree_id = :git_ref",
                        git_ref: git_ref)
        else
          commits.where("commits.id ilike :git_ref OR tree_id ilike :git_ref",
                        git_ref: (git_ref + "%"))
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

    def build_my_commits_filter(user, do_apply)
      lambda do |commits|
        if do_apply
          commits.where(
            "lower(commits.author_email) IN
              (SELECT lower(email_address) FROM email_addresses
                 WHERE email_addresses.user_id = :user_id)
              OR lower(commits.committer_email) IN
                (SELECT lower(email_address) FROM email_addresses
                  WHERE email_addresses.user_id = :user_id)", user_id: user.id,
          )
        else
          commits
        end
      end
    end

    def build_commits_by_branch_name_filter(branch_name)
      lambda do |commits|
        if branch_name.present?
          if /^\^.+/.match?(branch_name)
            commits.joins(:branches)
              .where("branches.name ~* ?", branch_name)
          else
            commits.joins(:branches)
              .where(branches: { name: branch_name.split(",").map(&:strip) })
          end
        else
          commits
        end
      end
    end

    def build_commits_by_repository_name_filter(repository_name)
      lambda do |commits|
        if repository_name.present?
          if /^\^.+/.match?(repository_name)
            commits.joins(branches: :repository)
              .where("repositories.name ~* ?", repository_name)
          else
            commits.joins(branches: :repository)
              .where(repositories: { name: repository_name.split(",").map(&:strip) })
          end
        else
          commits
        end
      end
    end

    def build_commits_by_page(page, per_page)
      lambda do |commits|
        if per_page.present?
          commits.page(page).per(Integer(per_page))
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
          # a bit ugly but actually faster then the recursive with query we used before
          # if the depth is limited; the form offers only up to depth 3
          query = commits.joins("JOIN branches AS heads ON commits.id = heads.current_commit_id")
                         .reorder("").distinct.select("commits.id AS id, commits.depth AS depth" \
                         ", heads.id AS branch_id ")
          sub_cs = query.map.with_index do |h, i|
            "(SELECT cs#{i}.id FROM commits AS cs#{i} " \
            " JOIN branches_commits AS bcs#{i} ON bcs#{i}.commit_id = cs#{i}.id " \
            " JOIN branches AS bs#{i} ON bcs#{i}.branch_id = bs#{i}.id " \
            " WHERE bs#{i}.id = '#{h[:branch_id]}'::UUID " \
            " AND cs#{i}.depth > #{h[:depth] - depth - 1} )"
          end.join(" UNION ").squish
          if sub_cs.present?
            commits.where(" commits.id in ( #{sub_cs} )")
          else
            commits
          end
        end
      end
    end
  end
end
