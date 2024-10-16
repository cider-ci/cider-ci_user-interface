#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Public::BadgesController < PublicController
  include Concerns::BadgeParamsBuilder

  layout "badge"

  def medium
    build_find_by_args
    @view_params = build_badge_params(*@find_by_args)
  end

  def small
    build_find_by_args
    set_job

    @view_params = build_small_badge_params(@job, *@find_by_args)

    if @job && !@job.public_view_permission?
      @view_params = build_small_badge_params_403(@view_params,
                                                  params[:job_name])
      if params.key?(:respond_with_200)
        render
      else
        render status: 403
      end
    elsif @job || params.key?(:respond_with_200)
      render
    else
      render status: 404
    end
  end

  def build_find_by_args
    @find_by_args = params[:repository_name],
                    params[:branch_name], params[:job_name]
  end

  def set_job
    @job = Job.find_by_repo_branch_name(*@find_by_args)
  end
end
