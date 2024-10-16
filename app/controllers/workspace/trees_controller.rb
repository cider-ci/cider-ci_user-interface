#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TreesController < WorkspaceController
  include Concerns::UrlBuilder
  include Concerns::HTTP

  def attachments
    @tree_attachments = TreeAttachment.where(tree_id: params[:tree_id])
  end

  def show
    @tree_id = params[:id]
    @tree_issues = TreeIssue.where(tree_id: @tree_id)
    @attachments = TreeAttachment.where(tree_id: @tree_id)
    @commits = Commit.where(
      " id IN ( WITH RECURSIVE recursive_commits(id) AS
          ( SELECT id FROM commits WHERE tree_id = ?
           UNION ALL SELECT submodule_commit_id
           FROM submodules, recursive_commits
           WHERE submodules.commit_id = recursive_commits.id )
        SELECT id FROM recursive_commits) ", @tree_id
    )
    @jobs = Job.where(tree_id: @commits.map(&:tree_id))
  end

  def get_project_configuration(tree_id)
    url = service_base_url("/cider-ci/repositories") +
          "/project-configuration/#{tree_id}"
    http_get(url)
  end

  def project_configuration
    @project_configuration_response = begin
        @tree_issues = TreeIssue.where(tree_id: params[:tree_id])
        get_project_configuration(params[:tree_id])
      rescue Faraday::ClientError => e
        Rails.logger.warn(Formatter.exception_to_log_s(e))
        e.response
      end
    status = @project_configuration_response[:status].presence ||
             @project_configuration_response.status
    case status
    when 200..299
      respond_to do |format|
        @project_configuration = JSON.parse @project_configuration_response.body
        format.html
        format.json do
          render json: JSON.pretty_generate(@project_configuration)
        end
        format.yaml do
          render content_type: "text/yaml", body: @project_configuration.to_yaml
        end
      end
    when 300..1000
      render :project_configuration_error
    else
      raise "Handle for #{@project_configuration_response[:status].presence} is missing"
    end
  end
end
