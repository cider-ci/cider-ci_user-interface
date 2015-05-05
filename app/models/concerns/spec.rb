#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.
#
module Concerns
  module Spec
    extend ActiveSupport::Concern

    included do
      validate :id_matches_data, on: :update

      before_create do |instance|
        instance.id = JobSpecification.id_hash(instance.data)
      end

      default_scope { order(:id) }

    end

    def id_matches_data
      errors.add(:data, 'is immutable') if  id != self.class.id_hash(self.data)
    end

    module ClassMethods
      UUID_NULL = UUIDTools::UUID.parse('00000000-0000-0000-0000-000000000000')

      def id_hash(data)
        UUIDTools::UUID.sha1_create(UUID_NULL, data.to_json).to_s
      end

      def find_or_create_by_data!(data)
        find_by(id: id_hash(data).to_s) || create!(data: data)
      end
    end

  end
end
