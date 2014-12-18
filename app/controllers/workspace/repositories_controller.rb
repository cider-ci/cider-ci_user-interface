#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::RepositoriesController < WorkspaceController 

  def names
    @repositories= Repository.reorder(name: :asc) \
      .instance_exec(params) do |params|
      (term= params[:term]).blank? ? self : where("name ilike ?",term<<'%')
    end.distinct.limit(25)
    render json: @repositories.pluck(:name)
  end

end
