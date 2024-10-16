module Workspace::JobsControllerModules
  module JobSelectionBuilder
    class SpecEmptyWarning < RuntimeError; end

    extend ActiveSupport::Concern
    include Concerns::UrlBuilder
    include Concerns::HTTP

    def set_runnable_jobs(id)
      all_jobs = fetch_project_configuration_jobs(id)
      @runnable_jobs = all_jobs.select { |j| j[:runnable] }
        .map { |j| j.except(:runnable, :reasons) }
      @un_runnable_jobs = all_jobs.reject { |j| j[:runnable] }
    end

    def get_jobs(id)
      url = service_base_url("/cider-ci/builder") + "/jobs/available/#{id}"
      JSON.parse(http_get(url).body)
    end

    def fetch_project_configuration_jobs(id)
      get_jobs(id).map(&:deep_symbolize_keys).map do |values|
        values.slice(:name, :description, :tree_id, :key, :runnable, :reasons)
      end.sort_by { |v| v[:name] }
    rescue RestClient::ResourceNotFound
      @alerts[:errors] << "There exists no cider-ci dot-file " \
      " `.cider-ci.yml` for the given tree-id."
      nil
    rescue RestClient::UnprocessableEntity => e
      @alerts[:errors] << e.response
      nil
    rescue RestClient::InternalServerError
      @alerts[:errors] << "An unspecified error occurred when " \
      "fetching the available jobs. See the logfiles " \
      "for details."
      nil
    rescue Faraday::ResourceNotFound => e
      @alerts[:errors] << "The project_configuration " \
                          "or an included resource was not found. "
      @alerts[:errors] << e.to_s + " " + e.response.to_s
      nil
    end
  end
end
