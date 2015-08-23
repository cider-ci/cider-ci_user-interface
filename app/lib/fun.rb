#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module Fun
  class << self

    def wrap_exception_with_redirect(controller, redirect_path)
      begin
        yield
      rescue Exception => e
        Rails.logger.error Formatter.exception_to_s(e)
        controller.redirect_to redirect_path,
                               flash: { errors: [Formatter.exception_to_s(e)] }
      end
    end

  end
end
