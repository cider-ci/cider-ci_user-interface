#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class WorkspaceController < ApplicationController

  before_action :require_sign_in

  helper_method \
    :branch_names_filter,
    :commit_text_search_filter,
    :commited_within_last_days_filter,
    :execution_tags_filter,
    :is_branch_head_filter,
    :repository_names_filter,
    :tree_id_filter,
    :with_branch_filter,
    :with_execution_filter

  def execution_tags_filter
    params.try('[]', 'execution_tags').try(:nil_or_non_blank_value) \
      .split(',').map(&:strip).reject(&:blank?).sort.uniq rescue []
  end

  def repository_names_filter
    generic_names_filter 'repository'
  end

  def branch_names_filter
    generic_names_filter 'branch'
  end

  def generic_names_filter(name)
    params.try('[]', name).try('[]', :names).try(:nil_or_non_blank_value) \
      .split(',').map(&:strip).reject(&:blank?) rescue []
  end

  def commited_within_last_days_filter
    Integer(params[:commited_within_last_days]) rescue 10
  end

  def commit_text_search_filter
    params.try('[]', 'commit').try('[]', :text).try(:nil_or_non_blank_value)
  end

  def tree_id_filter
    params.try('[]', 'tree_id').try(:nil_or_non_blank_value)
  end

  def require_sign_in
    render 'public/401', status: :unauthorized unless user?
  end

end
