module Concerns
  module SummaryBuilder
    extend ActiveSupport::Concern

    DEFAULT_OPTIONS = {
      orientation: :horizontal,
      embedded: true
    }

    def build_summary_properties(reponame, branchname, execution_names,
                              options = {})

      defaults = DEFAULT_OPTIONS.merge options

      branch = find_branch_by_reponame_and_branchname(reponame, branchname)

      defaults.merge(
        unless branch
          build_404_summary_properties(reponame, branchname)
        else
          unless branch.repository.public_view_permission
            build_403_summary_properties reponame
          else
            build_200_summary_properties(
              branch,
              find_executions_by_branch_and_names(branch, execution_names))
          end
        end)
    end

    def build_404_summary_properties(reponame, branchname)
      { status: 404,
        host_info_text: host_info_text,
        failed_info_text: "404 Not found: #{reponame} / #{branchname}" }
    end

    def build_403_summary_properties(reponame)
      { status: 403,
        host_info_text: host_info_text,
        failed_info_text: "403 Forbidden: #{reponame}" }
    end

    def build_200_summary_properties(branch, executions)
      { host_info_text: "#{host_info_text}",
        git_info_text: git_info_text(branch.repository, branch),
        executions: executions.map { |e| execution_info(e) } }
    end

    def execution_info(e)
      case e
      when Execution
        { text: "#{e.name}: #{execution_info_result_summary(e)}",
          class: e.state,
          href: workspace_execution_url(e) }
      else
        { text: "#{e}: Not available",
          class: 'unavailable' }
      end
    end

    def execution_info_result_summary(e)
      e.result['summary'] rescue "#{e.stats_summary} #{e.state}"
    end

    def host_info_text
      ('Cider-CI @ ' + ::Settings[:hostname]).squish
    end

    def git_info_text(repository, branch)
      "#{repository.name} / #{branch.name}".squish
    end

    def find_branch_by_reponame_and_branchname(repository_name, branch_name)
      Branch.joins(:repository)
      .where('lower(branches.name) = ?', branch_name.downcase)
      .where('lower(repositories.name) = ?', repository_name.downcase)
      .first
    end

    def find_executions_by_branch_and_names(branch, names)
      canonicalize_execution_names(names).map do |name|
        branch.executions \
        .where('lower(executions.name) = ?', name.downcase).first or name
      end
    end

    def canonicalize_execution_names(execution_names)
      case execution_names
      when String
        execution_names.split(/,|;/).map(&:squish)
      when Array
        execution_names.map(&:squish)
      end
    end

  end
end
