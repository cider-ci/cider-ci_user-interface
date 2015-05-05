#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TreesController < WorkspaceController
    include Concerns::UrlBuilder
    include Concerns::HTTP

    def attachments
      @tree_attachments = \
        TreeAttachment.where("path like '/#{params[:tree_id]}/%'") \
        .page(params[:page])
    end

    def get_dotfile(tree_id)
      url = service_base_url(::Settings.services.builder.http) +
        "/dotfile/#{tree_id}"
      http_get(url)
    end

    def dotfile
      @dotfile_response = get_dotfile(params[:tree_id])
      case @dotfile_response.status
      when 200..299
        @dotfile = JSON.parse @dotfile_response.body
      when 404
        render :dotfile_error
      when 500 
        render :dotfile_error
      else
        raise "Handle for #{@dotfile_response.status} is missing"
      end
    end

end
