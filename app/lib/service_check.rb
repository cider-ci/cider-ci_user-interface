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
      check_resource(url, connection)
    end

    def check_api
      check_service Settings.services.api.http,  Settings.basic_auth
    end

    def check_builder
      check_service Settings.services.builder.http,  Settings.basic_auth
    end

    def check_dispatcher
      check_service Settings.services.dispatcher.http,  Settings.basic_auth
    end

    def check_repository
      check_service Settings.services.repository.http,  Settings.basic_auth
    end

    def check_storage
      check_service Settings.services.storage.http,  Settings.basic_auth
    end

    def check_service(http_opts, basic_auth)
      url = service_base_url(http_opts) + '/status'
      check_resource url, basic_auth
    end

    def check_resource url, basic_auth
      begin 
        response= http_get(url, basic_auth.username, basic_auth.password)
        res= OpenStruct.new
        if response.status.between?(200,299)
          res.is_success = true
          res.content = JSON.parse(response.body)
        else
          res.is_success = false
          res.content = {message: response.body}
        end
        res
      rescue StandardError => e
        Rails.logger.warn Formatter.exception_to_log_s(e)
        res= OpenStruct.new
        res.is_success = false
        res.content = {error: e.to_s}
        res
      end
    end

  end

end
