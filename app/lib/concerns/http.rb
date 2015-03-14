module Concerns
  module HTTP
    extend ActiveSupport::Concern

    def http_get(url, username = ::Settings.basic_auth.username,
                 password = ::Settings.basic_auth.password)
      begin
        request = RestClient::Request.new(
          method: :get,
          url: url,
          user: username,
          password: password,
          verify_ssl: false,
          headers: { accept:  :json,
                     content_type:  :json })
        response = request.execute
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
