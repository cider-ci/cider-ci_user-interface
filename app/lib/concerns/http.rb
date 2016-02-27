module Concerns
  module HTTP
    extend ActiveSupport::Concern

    USER_NAME = 'ui-service'.freeze

    # TODO: disable RaiseError by default
    def http_get(url,
      username: USER_NAME,
      password: compute_password,
      raise_error: true, &block)

      http_request = Faraday.new(url: url) do |f|
        f.basic_auth username, password
        f.use Faraday::Response::RaiseError if raise_error
        f.request :retry
        f.adapter Faraday.default_adapter
        f.ssl.verify = false
      end

      http_request.get block
    end

    # NOTE this one doesn't raise!
    def http_do(method, url, body: nil,
      headers: {},
      username: USER_NAME,
      password: compute_password, &block)

      http_request = Faraday.new(url: url) do |f|
        f.basic_auth username, password
        # f.use Faraday::Response::RaiseError
        f.request :retry
        f.adapter Faraday.default_adapter
        f.ssl.verify = false
      end

      http_request.run_request method, url, body, headers, &block
    end

    def compute_password(username = USER_NAME)
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha1'),
        Settings.secret, username)
    end

  end

end
