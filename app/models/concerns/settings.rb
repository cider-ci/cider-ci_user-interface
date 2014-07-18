#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module Concerns
  module Settings
    extend ActiveSupport::Concern

    module ClassMethods
      def find
        @instance ||= find_or_create_by id: 0
      end
      def reload
        @instance = find_or_create_by id: 0
      end
    end
  end
end
