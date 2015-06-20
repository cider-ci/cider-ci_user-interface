#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module Formatter
  class << self

    def exception_to_s(e)
      case Rails.env
      when 'development'
        "#{e.class} #{e.message} #{application_trace(e).join('; ')}"
      else
        "#{e.class} #{e.message}"
      end
    end

    def exception_to_log_s(e, *more)
      rest = more.map(&:to_s).join(',')
      [e.class, e.message, application_trace(e).join(','), rest].join(' ### ')
    end

    def application_trace(e)
      e.backtrace.select do |l|
        l =~ Regexp.new(Rails.root.to_s)
      end.reject do |l|
        l =~ Regexp.new(Rails.root.join('vendor').to_s)
      end
    end

  end
end
