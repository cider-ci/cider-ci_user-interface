#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Admin::TimeoutSettingsController < AdminController

  def edit
    @timeout_settings = TimeoutSettings.find
  end

  def update
    @timeout_settings = TimeoutSettings.find
    @timeout_settings.update_attributes! params.require(:timeout_settings).permit!
    redirect_to edit_admin_timeout_settings_path(@timeout_settings),
                flash: { successes: [%(The timeout settings have been updated!)] }
  end

end
