module CiderCI
  module Data
    class << self
      def dump_core
        %w(users repositories).map do |entity|
          Hash[entity, entity.singularize.camelize.constantize \
               .all.map(&:attributes)]
        end
      end
    end
  end
end
