#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module Concerns
  module BaseSettings
    extend ActiveSupport::Concern

    module ClassMethods
      def find(*_args)
        find_or_create_by id: 0
        # this doesn't by us much anymore
        #        case RUBY_ENGINE
        #        when "jruby" # we are running one server
        #          @instance ||= find_or_create_by id: 0
        #        when "ruby"
        #          find_or_create_by id: 0
        #        else
        #          raise RuntimeError, "The ruby engine #{RUBY_ENGINE} is not supported"
        #        end
      end
    end
  end
end
