#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module ServiceCheck

  class << self

    include Concerns::HTTP
    include Concerns::UrlBuilder

    def check_api
      check_service Settings[:services][:api][:http]
    end

    def check_builder
      check_service Settings[:services][:builder][:http]
    end

    def check_dispatcher
      check_service Settings[:services][:dispatcher][:http]
    end

    def check_repository
      check_service Settings[:services][:repository][:http]
    end

    def check_storage
      check_service Settings[:services][:storage][:http]
    end

    def check_service(http_opts)
      url = service_base_url(http_opts) + '/status'
      check_resource url
    end

    def basic_auth_password(username)
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha1'),
        Settings[:secret], username)
    end

    def check_resource(url)
      begin
        response = http_get(url,
          username: 'ui-service',
          password: basic_auth_password('ui-service'),
          raise_error: false)
        res = OpenStruct.new
        if response.status.between?(200, 299)
          res.is_ok = true
          res.content = JSON.parse(response.body)
        else
          res.is_ok = false
          res.content =
            if response.headers['content-type'] =~ /json/
              JSON.parse(response.body)
            else
              { message: response.body }
            end
        end
        res
      rescue Exception => e
        Rails.logger.warn Formatter.exception_to_log_s(e)
        res = OpenStruct.new
        res.is_ok = false
        res.content = { error: e.to_s }
        res
      end
    end

  end

end
