#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TreesController < WorkspaceController
    include Concerns::UrlBuilder
    include Concerns::HTTP

    def attachments
      @tree_attachments = TreeAttachment \
        .where(tree_id: params[:tree_id]).page(params[:page])
    end

    def show
      @tree_id = params[:id]
      @attachments = TreeAttachment.where(tree_id: @tree_id)
      @commits = Commit.where(tree_id: @tree_id)
      @jobs = Job.where(tree_id: @tree_id)
    end

    def get_configfile(tree_id)
      url = service_base_url(::Settings.services.repository.http) +
        "/project-configuration/#{tree_id}"
      http_get(url)
    end

    def configfile
      @configfile_response =
        begin
          get_configfile(params[:tree_id])
        rescue Faraday::ClientError => e
          Rails.logger.warn(Formatter.exception_to_log_s(e))
          e.response
        end
      case @configfile_response[:status].presence || @configfile_response.status
      when 200..299
        @configfile = JSON.parse @configfile_response.body
      when 404
        render :configfile_error
      when 422
        render :configfile_error
      when 500
        render :configfile_error
      else
        raise "Handle for #{@configfile_response[:status].presence} is missing"
      end
    end

end
