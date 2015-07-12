module Workspace::JobsControllerModules
  module JobSelectionBuilder
    class SpecEmptyWarning < Exception; end
    extend ActiveSupport::Concern
    include Concerns::UrlBuilder
    include Concerns::HTTP

    def set_runnable_jobs(id)
      @runnable_jobs = fetch_configfile_jobs(id)
    end

    def get_jobs(id)
      url = service_base_url(::Settings.services.builder.http) +
        "/jobs/available/#{id}"
      JSON.parse(http_get(url).body)
    end

    def fetch_configfile_jobs(id)
      begin
        get_jobs(id).map(&:deep_symbolize_keys).map do |values|
          values.slice(:name,  :description, :tree_id, :key)
        end.sort_by { |v| v[:name] }

      rescue RestClient::ResourceNotFound
        @alerts[:errors] << 'There exists no cider-ci dot-file ' \
          ' `.cider-ci.yml` for the given tree-id.'
        nil
      rescue RestClient::UnprocessableEntity => e
        @alerts[:errors] << e.response
        nil
      rescue RestClient::InternalServerError
        @alerts[:errors] << 'An unspecified error occurred when '\
          'fetching the available jobs. See the logfiles '\
          'for details.'
        nil

      rescue Faraday::ResourceNotFound => e
        @alerts[:errors] << 'The configfile or an included resource was not found. '
        @alerts[:errors] << e.to_s + ' ' + e.response.to_s
        nil
      end
    end

  end

end
