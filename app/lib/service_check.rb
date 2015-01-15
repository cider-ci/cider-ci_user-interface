#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module ServiceCheck

  class << self

    include Concerns::HTTP
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

  end

end
