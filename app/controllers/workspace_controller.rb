#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class WorkspaceController < ApplicationController

  before_action :require_sign_in

  helper_method \
    :branch_names_filter, 
    :commit_text_search_filter,
    :commited_within_last_days_filter,
    :is_branch_head_filter,
    :execution_tags_filter,
    :repository_names_filter, 
    :with_branch_filter,
    :with_execution_filter

  def execution_tags_filter 
    params.try('[]',"execution_tags").try(:nil_or_non_blank_value) \
      .split(",").map(&:strip).reject(&:blank?).sort().uniq() rescue []
  end

  def repository_names_filter 
    params.try('[]',"repository").try('[]',:names).try(:nil_or_non_blank_value) \
      .split(",").map(&:strip).reject(&:blank?) rescue []
  end

  def branch_names_filter
    params.try('[]',"branch").try('[]',:names).try(:nil_or_non_blank_value) \
      .split(",").map(&:strip).reject(&:blank?) rescue []
  end

  def commited_within_last_days_filter
    Integer(params[:commited_within_last_days]) rescue nil
  end

  def commit_text_search_filter
    params.try('[]',"commit").try('[]',:text).try(:nil_or_non_blank_value)
  end

  def require_sign_in
    unless user?
      render "public/401", status: :unauthorized
      return 
    end
  end

end
