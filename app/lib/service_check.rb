#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

module ServiceCheck

  class << self

    def check_rabbitmq
      connection = Settings.messaging.connection
      url = "http://localhost:15672/api/vhosts/"
      begin 
        response= HttpMonkey.at(url).basic_auth(connection.username,connection.password).get
        {success: (response.code <= 299) ? true : false,
         code: response.code, 
         message: JSON.parse(response.body)}
      rescue Exception => e
        Rails.logger.error Formatter.exception_to_log_s(e, url)
        {succes: false}
      end

    end

    def check_api
      check_service Settings.api_service,  Settings.basic_auth
    end

    def check_builder
      check_service Settings.builder_service,  Settings.basic_auth
    end
     
    def check_dispatcher
      check_service Settings.dispatcher_service,  Settings.basic_auth
    end

    def check_repository
      check_service Settings.repository_service,  Settings.basic_auth
    end

    def check_storage
      check_service Settings.storage_service,  Settings.basic_auth
    end


    def check_service http_opts, basic_auth
      protocol= "http#{http_opts.ssl ? 's' : ''}"
      url = "#{protocol}://#{http_opts.host}:#{http_opts.port}#{http_opts.path}/status"

      begin 
        response= HttpMonkey.at(url).basic_auth(basic_auth.user,basic_auth.secret).get
        {success: (response.code <= 299) ? true : false,
         code: response.code, 
         message: JSON.parse(response.body)}
      rescue Exception => e
        Rails.logger.error Formatter.exception_to_log_s(e, url)
        {succes: false, message: "request failed"}
      end
    end

  end

end
