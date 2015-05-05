#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::AttachmentsController < WorkspaceController

  skip_before_action :require_sign_in, only: [:show]

  def show
    klass = params[:kind].camelize.constantize
    full_path = '/' + params[:path]
    if @attachment = klass.find_by(path: full_path)
      require_sign_in unless public_view_permission?(@attachment)
    else
      render_404 "You are looking for the #{klass.name} #{full_path}.
        It doesn't exist at this time. You can try again later.".squish
    end
  end

  def public_view_permission?(attachment)
    case attachment
    when TreeAttachment
      Job.where(tree_id: @attachment.tree_id) \
        .limit(1).first.public_view_permission?
    when TrialAttachment
      Job.joins(tasks: :trials) \
        .where('trials.id = ? ', @attachment.trial_id) \
        .limit(1).first.public_view_permission?
    end
  end

end
