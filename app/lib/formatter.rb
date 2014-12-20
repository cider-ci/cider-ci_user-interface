#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module Formatter
  class << self

    def exception_to_s e

      case Rails.env
      when "development"
        e.class.to_s + " " + e.message.to_s + "\n\n" + 
          e.backtrace.select{|l| l =~ Regexp.new(Rails.root.to_s)}.join("\n") 
        # + "\n\n" + e.backtrace.join("\n") 
      else
        e.class.to_s + " " + e.message.to_s
      end
    end

    def exception_to_log_s e, *more 
      message= e.message.to_s 
      trace= e.backtrace.select{|l| l =~ Regexp.new(Rails.root.to_s)}.reject{|l| 
          l =~ Regexp.new(Rails.root.join("vendor").to_s)}.join(", ") 
      rest= more.map(&:to_s).join(",")
      [message,trace,rest].join(" ### ")
    end

  end
end
