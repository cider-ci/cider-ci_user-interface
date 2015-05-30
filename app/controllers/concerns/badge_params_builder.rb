module Concerns
  module BadgeParamsBuilder
    extend ActiveSupport::Concern

    def build_badge_params(repository_name, branch_name, job_name)
      repository = find_repository_by_name repository_name

      branch = find_branch_by_name_and_repository branch_name, repository

      job = find_job_by_name_and_branch job_name, branch

      { repository_name: (repository.try(:name) or repository_name),
        branch_name: (branch.try(:name) or branch_name),
        job_name: (job.try(:name) or job_name),
        job_link: job ? workspace_job_url(job) : nil,
        state: (job.try(:state) or 'unavailable'),
        context: Rails.application.config.action_controller.relative_url_root,
        hostname: ::Settings[:hostname],
        message: build_message(job)
      }
    end

    def build_small_badge_params(job, repository_name,
                                 branch_name, job_name)

      host_info_text = ('Cider-CI @ ' + ::Settings[:hostname]).squish
      git_info_text = (repository_name + ' / ' + branch_name).squish
      job_info_text = if job
                             job.name + ' ' + job.state
                      else
                             "#{job_name} -
                             404 Not found, try again later".squish
                      end

      { host_info_text: host_info_text,
        host_info_text_width: FontMetrics.text_width(host_info_text),
        git_info_text: git_info_text,
        git_info_text_width: FontMetrics.text_width(git_info_text),
        job_info_text: job_info_text,
        job_info_text_width: FontMetrics.text_width(job_info_text),
        state: (job.try(:state) or 'unavailable')
      }
    end

    def build_small_badge_params_403(view_params, job_name)
      job_info_text = "#{job_name} - 403 Forbidden"
      view_params.merge(
        job_info_text: job_info_text,
        job_info_text_width: FontMetrics.text_width(job_info_text),
        state: 'failed')
    end

    def build_message(job)
      if job && state = job[:state]
        stat = job.job_stat
        case state
        when 'failed'
          " #{stat.failed}/#{stat.total} #{job[:state]}"
        when 'passed'
          " #{stat.total} #{job[:state]}"
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

    def find_job_by_name_and_branch(job_name, branch)
      if branch
        Job.where('jobs.tree_id = ?',
                  branch.current_commit.tree_id) \
        .where('lower(jobs.name) = ?',
               job_name.downcase).first
      end
    end

  end
end
