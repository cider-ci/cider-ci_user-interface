module Concerns
  module UrlBuilder
    extend ActiveSupport::Concern

    def service_base_url(conf)
      '' +
        (conf.ssl.nil? ? '' : Concerns::UrlBuilder.protocol(conf)) +
        (conf.host ? "//#{conf.host}" : '') +
        (conf.port ? ":#{conf.port}" : '') +
        conf.path
    end

    def self.protocol(conf)
      conf.ssl ? 'https:' : 'http:'
    end

  end
end
