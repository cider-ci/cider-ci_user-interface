module Concerns
  module SessionHelper
    extend ActiveSupport::Concern

    included do
      helper_method :session_adjust_reload_timeout
    end

    def session_adjust_reload_timeout(default_value)
      case session[:reload_frequency]
      when "aggressive"
        (default_value / 3.0).floor
      when "slow"
        (default_value * 10)
      else
        default_value
      end
    end
  end
end
