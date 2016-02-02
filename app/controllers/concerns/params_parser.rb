module Concerns
  module ParamsParser
    extend ActiveSupport::Concern

    included do
      helper_method \
        :branch_name_param,
        :commits_per_page_param,
        :commits_text_search_param,
        :depth_param,
        :git_ref_param,
        :my_commits?,
        :repository_name_param
    end

    def git_ref_param
      params[:git_ref].try(:squish).try(:downcase).presence
    end

    def repository_name_param
      params[:repository_name].try(:strip)
    end

    def branch_name_param
      params[:branch_name].try(:strip)
    end

    def commits_text_search_param
      params.try('[]', 'commits_text_search').presence
    end

    def commits_per_page_param
      integer_param :per_page, 7
    end

    def per_page_param
      integer_param :per_page, Kaminari.config.default_per_page
    end

    def my_commits?
      params[:my_commits].presence == 'true'
    end

    def depth_param
      integer_param :depth, 0
    end

    private

    def integer_param(name, default)
      Integer(params[name].presence || default)
    end

  end
end
