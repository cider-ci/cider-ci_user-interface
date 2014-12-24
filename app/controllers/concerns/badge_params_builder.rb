module Concerns
  module BadgeParamsBuilder
    extend ActiveSupport::Concern

    def build_badge_params(repository_name, branch_name, execution_name)
      repository = find_repository_by_name repository_name

      branch = find_branch_by_name_and_repository branch_name, repository

      execution = find_execution_by_name_and_branch execution_name, branch

      { repository_name: (repository.try(:name) or repository_name),
        branch_name: (branch.try(:name) or branch_name),
        execution_name: (execution.try(:name) or execution_name),
        execution_link: execution ? workspace_execution_url(execution) : nil,
        state: (execution.try(:state) or 'unavailable'),
        context: Rails.application.config.action_controller.relative_url_root,
        hostname: ::Settings[:hostname],
        message: build_message(execution)
      }
    end

    def build_small_badge_params(execution, repository_name,
                                 branch_name, execution_name)

      host_info_text = ('Cider-CI @ ' + ::Settings[:hostname]).squish
      git_info_text = (repository_name + ' / '  + branch_name).squish
      execution_info_text = if execution
                             execution.name + ' ' + execution.state
                            else
                             "#{execution_name} -
                             404 Not found, try again later".squish
                            end

      { host_info_text: host_info_text,
        host_info_text_width: FontMetrics.text_width(host_info_text),
        git_info_text: git_info_text,
        git_info_text_width: FontMetrics.text_width(git_info_text),
        execution_info_text: execution_info_text,
        execution_info_text_width: FontMetrics.text_width(execution_info_text),
        state: (execution.try(:state) or 'unavailable')
      }
    end

    def build_small_badge_params_403(view_params, execution_name)
      execution_info_text = "#{execution_name} - 403 Forbidden"
      view_params.merge(
        execution_info_text: execution_info_text,
        execution_info_text_width: FontMetrics.text_width(execution_info_text),
        state: 'failed')
    end

    def build_message(execution)
      if execution && state = execution[:state]
        stat = execution.execution_stat
        case state
        when 'failed'
          " #{stat.failed}/#{stat.total} #{execution[:state]}"
        when 'passed'
          " #{stat.total} #{execution[:state]}"
        else
          state
        end
      else
        ' not available'
      end
    end

    def find_repository_by_name(repository_name)
      Repository.where(
        'lower(repositories.name) = :repository',
        repository: repository_name.downcase).first
    end

    def find_branch_by_name_and_repository(branch_name, repository)
      repository && repository.branches
      .where('lower(branches.name) = ?',
             branch_name.downcase).first
    end

    def find_execution_by_name_and_branch(execution_name, branch)
      if branch
        Execution.where('executions.tree_id = ?',
                        branch.current_commit.tree_id) \
        .where('lower(executions.name) = ?',
               execution_name.downcase).first
      end
    end

  end
end
