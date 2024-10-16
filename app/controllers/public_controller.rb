#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class PublicController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:sign_out]

  include ActionView::Helpers::TextHelper
  include Concerns::ServiceSession
  include Concerns::SummaryBuilder
  include Concerns::SummaryRenderer

  def show
  end

  def build_items(row)
    row.try(:[], "items").map(&:deep_symbolize_keys).map do |item|
      render_summary_svg(
        build_summary_properties(
          item[:repository_name], item[:branch_name],
          item[:job_name], orientation: :vertical,
        )
      )
    end
  end

  def redirect_to_job
    if @job = Job.find_by_repo_branch_name(params[:repository_name],
                                           params[:branch_name],
                                           params[:job_name])
      redirect_to workspace_job_path(@job)
    else
      render_404_job_not_found
    end
  end

  def redirect_to_tree_attachment_content
    if @job = Job.find_by_repo_branch_name(params[:repository_name],
                                           params[:branch_name],
                                           params[:job_name])
      if tree_attachment = TreeAttachment
        .find_by(path: "/#{@job.tree_id}/#{params[:path]}")
        redirect_to workspace_attachment_path("tree_attachment", tree_attachment.path)
      else
        render_404 "You are looking for the attchment `#{params[:path]}`
           with the tree-id `#{truncate(@job.tree_id, length: 10)}`.
           It doesn't exist at this time. You can try again later.".squish
      end
    else
      render_404_job_not_found
    end
  end

  def render_404_job_not_found
    render_404 "You are looking for the job #{params[:job_name]}
          of the branch #{params[:branch_name]}
          and the repository #{params[:repository_name]}
          It doesn't exist at this time. You can try again later.".squish
  end

  def sign_out
    reset_session
    cookies.delete "cider-ci_services-session"
    redirect_to current_path,
      flash: { successes: ["You have been signed out!"] }
  end
end
