#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.
#

class WorkspaceController < ApplicationController
  include Concerns::ParamsParser
  include Concerns::CommitsFilter

  before_action :require_sign_in

  def index
    @my = my_workspace?
    set_commits_for_index
    @jobs = Job.where(tree_id: @commits.map(&:tree_id)).reorder(created_at: :desc)
  end

  def my_workspace?
    begin
      if current_user and (not current_user.workspace_filters)
        current_user.update! workspace_filters: get_filter_params
      end
      user_workspace_filter.deep_symbolize_keys == get_filter_params.deep_symbolize_keys
    rescue Exception
      false
    end
  end

  def set_commits_for_index
    @commits = Commit.all
    .apply(build_commits_by_repository_name_filter(repository_name_param))
    .apply(build_commits_by_branch_name_filter(branch_name_param))
    .apply(build_text_search_filter(commits_text_search_param))
    .apply(build_git_ref_filter(git_ref_param))
    .apply(build_commits_by_depth_filter(integer_param(:depth, 0)))
    .apply(build_commits_by_page(params[:page], commits_per_page_param))
    .distinct.reorder(committer_date: :desc, depth: :desc)
      .select(:author_email, :committer_email, :author_date, :author_name,
        :committer_date, :committer_name,
        :depth, :id, :subject, :tree_id, :updated_at)
  end

  def get_filter_params
    { repository_name: repository_name_param.presence,
      branch_name: branch_name_param.presence,
      git_ref: git_ref_param,
      commits_text_search: commits_text_search_param,
      depth: depth_param,
      per_page: commits_per_page_param
    }
  end

  def filter
    case request.method
    when 'GET'
      redirect_to workspace_path(user_workspace_filter), flash: Hash[flash.to_a]
    when 'POST'
      current_user.update! workspace_filters: get_filter_params
      redirect_to workspace_path(user_workspace_filter)
    end
  end

  def tree_id_filter
    params.try('[]', 'tree_id').presence
  end

  def require_sign_in
    render 'public/401', status: :unauthorized unless user?
  end

  SHOW_RAW_PERMITTED_TABLES = %w(trials scripts)

  def show_raw
    @table_name = params[:table_name]
    @where_condition = JSON.parse(params['where']).with_indifferent_access
    @attributes = @table_name.singularize.camelize\
      .constantize.find_by(@where_condition).attributes

    unless SHOW_RAW_PERMITTED_TABLES.include? @table_name
      render 'public/403', status: :forbidden
    else
      respond_to do |format|
        format.html
        format.json { render json: @attributes }
        format.yaml { render text:  @attributes.to_yaml, content_type: 'text/yaml' }
      end
    end
  end

end
