module CiderCI
  module Data
    class << self

      def dump_core
        %w(users repositories).map do |entity|
          Hash[entity, entity.singularize.camelize.constantize \
               .all.map(&:attributes)]
        end
      end

      def import_core(data)
        data = data.deep_symbolize_keys
        Repository.destroy_all
        data.each do |table_name, values|
          model = table_name.to_s.singularize.camelize.constantize
          values.each do |properties|
            attribute_names = model.attribute_names.map(&:to_sym)
            update_properties = properties.slice(*attribute_names)
            model.find_or_initialize_by(id: update_properties[:id]) \
              .update_attributes! update_properties
          end
        end
      end

    end
  end
end
