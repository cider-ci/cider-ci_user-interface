module Workspace::ExecutionsControllerModules
  module ExecutionSelectionBuilder
    class SpecEmptyWarning < Exception; end
    extend ActiveSupport::Concern
    include Concerns::UrlBuilder
    include Concerns::HTTP

    def set_creatable_executions(id)
      @creatable_executions =
        fetch_dotfile_executions(id) || formatted_db_definitions
    end

    def get_executions(id)
      url = service_base_url(::Settings.services.builder.http) +
        "/executions/available/#{id}"
      http_get(url)[:message]
    end

    def fetch_dotfile_executions(id)
      begin
        get_executions(id).map(&:deep_symbolize_keys).map do |values|
          values.slice(:name, :specification_id, :description, :tree_id)
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
          'fetching the available executions. See the logfiles '\
          'for details.'
        nil
    end

    def formatted_db_definitions
      Definition.all.map do |defi|
        Array[defi.name,
              { name: defi.name,
                default: defi.is_default,
                description: defi.description,
                specification_id: defi.specification_id }]
      end.instance_eval { Hash[self] }.deep_symbolize_keys
    end

  end

end
