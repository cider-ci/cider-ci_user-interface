module Concerns
  module SummaryBuilder
    extend ActiveSupport::Concern

    DEFAULT_OPTIONS = {
      orientation: :horizontal,
      embedded: true
    }.freeze

    def build_summary_properties(reponame, branchname, job_names,
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
              find_jobs_by_branch_and_names(branch, job_names))
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

    def build_200_summary_properties(branch, jobs)
      { host_info_text: host_info_text.to_s,
        git_info_text: git_info_text(branch.repository, branch),
        jobs: jobs.map { |e| job_info(e) } }
    end

    def job_info(e)
      case e
      when Job
        { text: "#{e.name}: #{job_info_result_summary(e)}",
          class: e.state,
          href: workspace_job_url(e) }
      else
        { text: "#{e}: Not available",
          class: 'unavailable' }
      end
    end

    def job_info_result_summary(e)
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

    def find_jobs_by_branch_and_names(branch, names)
      canonicalize_job_names(names).map do |name|
        branch.jobs \
              .where('lower(jobs.name) = ?', name.downcase).first or name
      end
    end

    def canonicalize_job_names(job_names)
      case job_names
      when String
        job_names.split(/,|;/).map(&:squish)
      when Array
        job_names.map(&:squish)
      end
    end

  end
end
