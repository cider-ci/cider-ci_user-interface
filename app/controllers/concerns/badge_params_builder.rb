module Concerns
  module BadgeParamsBuilder
    extend ActiveSupport::Concern

    def build_badge_params repository_name, branch_name, execution_name

      repository= find_repository_by_name repository_name

      branch= find_branch_by_name_and_repository branch_name, repository

      execution= find_execution_by_name_and_branch execution_name, branch
        
      { repository_name: (repository.try(:name) or repository_name),
        branch_name: (branch.try(:name) or branch_name),
        execution_name: (execution.try(:name) or execution_name),
        execution_link: execution ? workspace_execution_url(execution) : nil, 
        state: (execution.try(:state) or "unavailable"),
        context: Rails.application.config.action_controller.relative_url_root,
        hostname: ::Settings[:hostname],
        message: build_message(execution)
      }

    end

    private 

    def build_message execution
      if execution && state= execution[:state]
        stat= execution.execution_stat
        case state
        when "failed"
          " #{stat.failed}/#{stat.total} #{execution[:state]}"
        when "passed"
          " #{stat.total} #{execution[:state]}"
        end
      else
        " not available"
      end
    end

    def find_repository_by_name repository_name
      Repository.where(
        "lower(repositories.name) = :repository",
        repository: repository_name.downcase).first
    end

    def find_branch_by_name_and_repository branch_name, repository
      repository && repository.branches
      .where("lower(branches.name) = ?", 
             branch_name.downcase).first
    end


    def find_execution_by_name_and_branch execution_name, branch
      if branch 
        Execution.where("executions.tree_id = ?", 
                        branch.current_commit.tree_id) \
        .where("lower(executions.name) = ?", 
               execution_name.downcase).first
      end
    end



  end
end


