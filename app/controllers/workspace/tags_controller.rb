#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TagsController < WorkspaceController 

  def index
    @tags= Tag.reorder(tag: :asc) \
      .instance_exec(params) do |params|
      (term= params[:term]).blank? ? self : where("tag ilike ?",term<<'%')
    end.distinct.limit(25)

    render json: @tags.pluck(:tag)
  end

end

