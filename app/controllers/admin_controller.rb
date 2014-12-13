#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class AdminController < ApplicationController

  before_action do
    unless admin? 
      render "public/403", status: :forbidden
    end
  end

  def index
  end

end
