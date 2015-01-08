#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module ServiceCheck

  class << self

    include Concerns::UrlBuilder

    def check_rabbitmq
      connection = Settings.messaging.connection
      url = 'http://localhost:15672/api/vhosts/'
      http_get url, connection.username, connection.password
    end

    def check_api
      check_service Settings.internal_api_service,  Settings.basic_auth
    end

    def check_builder
      check_service Settings.internal_builder_service,  Settings.basic_auth
    end

    def check_dispatcher
      check_service Settings.internal_dispatcher_service,  Settings.basic_auth
    end

    def check_repository
      check_service Settings.internal_repository_service,  Settings.basic_auth
    end

    def check_storage
      check_service Settings.internal_storage_service,  Settings.basic_auth
    end

    def check_service(http_opts, basic_auth)
      url = service_base_url(http_opts) + '/status'
      http_get(url, basic_auth.user, basic_auth.secret)
    end

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
