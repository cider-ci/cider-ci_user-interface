module Concerns
  module UrlBuilder
    extend ActiveSupport::Concern
    extend self

    included do
      if self < ActionController::Base
        helper_method :api_path
      end
    end

    def service_base_url(conf, _options = {})
      Settings[:server_base_url] + service_path(conf)
    end

    def service_path(conf)
      if conf.is_a? Hash
        conf[:path] || "#{conf[:context]}#{conf[:sub_context]}"
      else
        conf.to_s
      end
    end

    def api_path
      service_path("/cider-ci/api")
    end

    def api_browser_path(resource_path = "")
      "#{api_path}/api-browser/index.html##{api_path}#{resource_path}"
    end
  end
end
