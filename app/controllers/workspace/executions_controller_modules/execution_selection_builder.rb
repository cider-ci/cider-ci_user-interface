module Workspace::ExecutionsControllerModules
  module ExecutionSelectionBuilder
    class SpecEmptyWarning < Exception; end
    extend ActiveSupport::Concern
    include Concerns::UrlBuilder

    def set_creatable_executions(id)
      db_definitions = formatted_db_definitions
      dotfile_definitions = get_dotfile_definitions_with_rescue id

      definitions = db_definitions.merge(dotfile_definitions) \
        .map {  |_, v| v }.sort_by { |v| v[:name] }

      @creatable_executions = definitions.map do |values|
        values.slice(:name, :specification_id, :description).merge(tree_id: id)
      end.reject do |values|
        Execution.find_by(tree_id: id, name: values[:name])
      end.sort_by { |v|v[:name] }
    end

    private

    def selected_data_value(d)
      d.select do |k|
        %w(name specification_id).include? k.to_s
      end.to_json
    end

    def format_dotfile_definitions(data)
      data.map do |name, properties|
        [name, properties.merge(
          name: name.to_s,
          specification_id: Specification \
          .find_or_create_by_data!(properties[:specification]).id)]
      end.instance_eval { Hash[self] }.deep_symbolize_keys
    end

    def http_get(id)
      url = service_base_url(Settings.internal_repository_service) +
        "/path-content/#{id}/.cider-ci.yml"
      RestClient::Resource.new(url, Settings.basic_auth.user,
                               Settings.basic_auth.secret).get
    end

    def get_dotfile_definitions(id)
      response = http_get id

      raise SpecEmptyWarning,  \
            'The cider-ci dot-file `.cider-ci.yml` is empty. ' \
            'No further executions are available.' if response.body.blank?

      executions_spec =
        YAML.load(response.body).deep_symbolize_keys[:executions]

      raise SpecEmptyWarning,
            'The `executions` property in the cider-ci dot-file ' \
            '`.cider-ci.yml` is not present or empty. ' \
            'No further executions are available.' if executions_spec.empty?

      format_dotfile_definitions executions_spec
    end

    def get_dotfile_definitions_with_rescue(id)
      begin

        @cider_ci_dot_file_cache ||= {}
        @cider_ci_dot_file_cache[id] ||= get_dotfile_definitions(id)

      rescue RestClient::ResourceNotFound
        @alerts[:warnings] <<  \
        'The recommended way to specify available executions is to use ' \
        'the cider-ci dot-file `.cider-ci.yml`. '  \
        'However, there is no cider-ci dot-file for this commit. '
        {}

      rescue Psych::SyntaxError
        @alerts[:errors] <<  \
          'There is a syntax error in the cider-ci dot-file `.cider-ci.yml`. ' \
          'No further executions are available. '
        {}

      rescue SpecEmptyWarning => e
        @alerts[:warnings] << e.to_s
        {}

      rescue Exception => e
        Rails.logger.warn Formatter.exception_to_log_s e
        @alerts[:errors] << 'An error occurred while processing ' \
          'the executions from the cider-ci dot-file `.cider-ci.yml`. ' \
          'No further executions are available. '
        {}

      end
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
