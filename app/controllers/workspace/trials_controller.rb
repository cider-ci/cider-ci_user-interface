#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TrialsController < WorkspaceController

  skip_before_action :require_sign_in,
                     only: [:show, :attachments]

  def show
    @trial = Trial.find params[:id]
    require_sign_in unless @trial.task.execution.public_view_permission?
    @scripts = @trial.scripts
  end

  def attachments
    @trial = Trial.find params[:id]
    require_sign_in unless @trial.task.execution.public_view_permission?
    @trial_attachments = @trial.trial_attachments.page(params[:page])
  end

end
