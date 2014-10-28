#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Public::BadgesController < PublicController 
  include Concerns::BadgeParamsBuilder

  layout 'badge'

  def medium 
    @view_params= build_badge_params params[:repository_name], 
      params[:branch_name], params[:execution_name]
  end

end
