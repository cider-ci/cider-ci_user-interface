#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Public::BadgesController < PublicController
  include Concerns::BadgeParamsBuilder

  layout 'badge'

  def medium
    build_find_by_args
    @view_params = build_badge_params(*@find_by_args)
  end

  def small
    build_find_by_args
    set_execution

    @view_params = build_small_badge_params(@execution, *@find_by_args)

    if @execution and (not @execution.public_view_permission?)
      @view_params = build_small_badge_params_403(@view_params,
                                                  params[:execution_name])
      if params.key?(:respond_with_200)
        render
      else
        render status: 403
      end
    else
      if @execution or params.key?(:respond_with_200)
        render
      else
        render status: 404
      end
    end
  end

  def build_find_by_args
    @find_by_args = params[:repository_name],
                    params[:branch_name], params[:execution_name]
  end

  def set_execution
    @execution = Execution.find_by_repo_branch_name(*@find_by_args)
  end

end
