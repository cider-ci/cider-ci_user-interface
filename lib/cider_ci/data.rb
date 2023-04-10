module CiderCI
  module Data
    class << self

      def import(filename)
        data = YAML.load_file(filename).with_indifferent_access

        data[:managed_users].try(:each) do |login, config|
          create_and_or_update User, 'login', login, config
        end

        data[:managed_repositories].try(:each) do |git_url, config|
          mapped_config = map_repository_config(config)
          create_and_or_update Repository, 'git_url', git_url, mapped_config
        end
      end

      def map_repository_config config
        config.map do |k,v|
          [k, map_repository_attributes(v)]
        end.to_h
      end

      def map_repository_attributes attributes
        attributes.with_indifferent_access.to_a.map do |k,v|
          mapped_key = case k.to_sym
                       when :foreign_api_repo
                         :remote_api_name
                       when :foreign_api_owner
                         :remote_api_namespace
                       when :foreign_api_authtoken
                         :remote_api_token
                       when :foreign_api_token_bearer
                         :remote_api_token_bearer
                       when :foreign_api_type
                         :remote_api_type
                       when :foreign_api_endpoint
                         :remote_api_endpoint
                       when :git_fetch_and_update_interval
                         :remote_fetch_interval
                       else
                         k
                       end
          [mapped_key, v]
        end.to_h
      end

      def create_and_or_update(entity, primary_attribute_name,
        primary_attribute, config)

        primary_map = { primary_attribute_name => primary_attribute }

        instance = entity.find_by(primary_map)

        create_attributes = config['create_attributes'].presence || {}

        instance ||= entity.create! primary_map.merge(create_attributes.to_h)

        update_attributes = config['update_attributes'].presence

        if (instance && update_attributes)
          instance.update! update_attributes.to_h
        end
      end

    end
  end
end
