#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.


class Workspace::AttachmentsController < WorkspaceController 

  skip_before_action :require_sign_in, only: [:show]


  def show
    klass= params[:kind].camelize.constantize
    full_path= "/"+ params[:path]

    if @attachment= klass.find_by(path: full_path)

      public_view_permission= \
        case @attachment
        when TreeAttachment
          Execution.where(tree_id: @attachment.tree_id) \
            .limit(1).first.public_view_permission?
        when TrialAttachment
            Execution.joins(tasks: :trials) \
            .where("trials.id = ? ", @attachment.trial_id) \
            .limit(1).first.public_view_permission?
        end

      require_sign_in unless public_view_permission


    else
      flash[:warning]= [%<You are looking for the #{klass.name} #{full_path}. >,
        "It doesn't exist at this time. You can try again later."].join("")
      render "/public/404", status: :not_found
    end

  end

end


