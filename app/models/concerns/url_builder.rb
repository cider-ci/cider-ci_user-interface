module Concerns
  module UrlBuilder
    extend ActiveSupport::Concern
    extend self

    included do
      if self < ActionController::Base
        helper_method :service_base_url, :protocol, :api_path
      end
    end

    def service_base_url(conf, options = {})
      Settings.server_base_url + service_path(conf)
    end

    def service_path(conf)
      (conf.path || "#{conf.context}#{conf.sub_context}")
    end

    def protocol(conf, options = {})
      unless options[:omit_protocol]
        conf.ssl ? 'https:' : 'http:'
      else
        ''
      end
    end

    def api_path
      service_path(Settings.services.api.http_external)
    end

  end
end
