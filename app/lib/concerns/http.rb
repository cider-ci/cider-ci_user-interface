module Concerns
  module HTTP
    extend ActiveSupport::Concern

    # TODO: disable RaiseError by default
    def http_get(url, username = ::Settings.basic_auth.username,
                 password = ::Settings.basic_auth.password, &block)

      http_request = Faraday.new(url: url) do |f|
        f.basic_auth username, password
        f.use Faraday::Response::RaiseError
        f.request :retry
        f.adapter Faraday.default_adapter
        f.ssl.verify = false
      end

      http_request.get block
    end

    # NOTE this one doesn't raise!
    def http_do(method, url, username = ::Settings.basic_auth.username,
                 password = ::Settings.basic_auth.password, &block)

      http_request = Faraday.new(url: url) do |f|
        f.basic_auth username, password
        # f.use Faraday::Response::RaiseError
        f.request :retry
        f.adapter Faraday.default_adapter
        f.ssl.verify = false
      end

      http_request.run_request method, url, nil, nil, &block
    end

  end

end
