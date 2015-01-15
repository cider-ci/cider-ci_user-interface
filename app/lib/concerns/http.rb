module Concerns
  module HTTP
    extend ActiveSupport::Concern

    def http_get(url, username, password)
      begin
        response = HttpMonkey.at(url).basic_auth(username, password).get
        { success: (response.code <= 299) ? true : false,
          code: response.code,
          message: JSON.parse(response.body) }
      rescue Exception => e
        Rails.logger.error Formatter.exception_to_log_s(e, url)
        { succes: false, message: 'request failed' }
      end
    end

  end
end
