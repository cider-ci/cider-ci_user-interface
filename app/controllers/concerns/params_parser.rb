module Concerns
  module ParamsParser
    extend ActiveSupport::Concern

    included do
      helper_method \
        :branches_names_params,
        :commits_text_search_param,
        :depth_param,
        :git_ref_param,
        :commits_per_page_param,
        :repositories_names_param
    end

    def git_ref_param
      params[:git_ref].try(:squish).try(:downcase).presence
    end

    def repositories_names_param
      extract_comma_separated_param :repositories_names
    end

    def branches_names_params
      extract_comma_separated_param :branches_names
    end

    def commits_text_search_param
      params.try('[]', 'commits_text_search').presence
    end

    def commits_per_page_param
      integer_param :per_page, 6
    end

    def per_page_param
      integer_param :per_page, Kaminari.config.default_per_page
    end

    def depth_param
      integer_param :depth, 0
    end

    private

    def integer_param(name, default)
      Integer(params[name].presence || default)
    end

    def extract_comma_separated_param(sym)
      params.try('[]', sym).presence \
        .split(',').map(&:strip).reject(&:blank?) rescue []
    end

  end
end
