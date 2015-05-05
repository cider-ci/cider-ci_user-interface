module Workspace::JobsControllerModules
  module JobSelectionBuilder
    class SpecEmptyWarning < Exception; end
    extend ActiveSupport::Concern
    include Concerns::UrlBuilder
    include Concerns::HTTP

    def set_runnable_jobs(id)
      @runnable_jobs =
        fetch_dotfile_jobs(id) || formatted_db_definitions
    end

    def get_jobs(id)
      url = service_base_url(::Settings.services.builder.http) +
        "/jobs/available/#{id}"
      JSON.parse(http_get(url).body)
    end

    def fetch_dotfile_jobs(id)
      begin
        get_jobs(id).map(&:deep_symbolize_keys).map do |values|
          values.slice(:name,  :description, :tree_id)
        end.sort_by { |v| v[:name] }

      rescue RestClient::ResourceNotFound
        @alerts[:errors] <<  'There exists no cider-ci dot-file ' \
          ' `.cider-ci.yml` for the given tree-id.'
        nil
      rescue RestClient::UnprocessableEntity => e
        @alerts[:errors] << e.response
        nil
      end
      rescue RestClient::InternalServerError
        @alerts[:errors] <<  'An unspecified error occurred when '\
          'fetching the available jobs. See the logfiles '\
          'for details.'
        nil
    end

    def formatted_db_definitions
      Definition.all.map do |defi|
        Array[defi.name,
              { name: defi.name,
                default: defi.is_default,
                description: defi.description,
                job_specification_id: defi.job_specification_id }]
      end.instance_eval { Hash[self] }.deep_symbolize_keys
    end

  end

end
