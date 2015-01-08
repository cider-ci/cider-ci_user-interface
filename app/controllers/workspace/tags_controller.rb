#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TagsController < WorkspaceController
  include Concerns::JsonForAutocomplete

  def index
    render json: build_single_column_json_for_autocomplete(Tag, 'tag')
  end

end
