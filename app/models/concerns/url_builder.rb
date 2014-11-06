module Concerns
  module UrlBuilder
    extend ActiveSupport::Concern

    def service_base_url conf
      "" +
        (conf.ssl == nil ? "" : (conf.ssl ? "https:" : "http:")) +
        (conf.host ? "//#{conf.host}" : "" ) +
        (conf.port ? ":#{conf.port}" : "") +
        conf.path
    end

  end
end


