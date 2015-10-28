#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Admin::WelcomePageSettingsController < AdminController

  def edit
    @welcome_page_settings = WelcomePageSettings.find
    @welcome_message =
      params[:welcome_page_settings].try(:[], 'welcome_message') ||
        @welcome_page_settings.welcome_message
  end

  def update
    rescue_path = edit_admin_welcome_page_settings_path(
      params[:welcome_page_settings])

    Fun.wrap_exception_with_redirect self, rescue_path do
      ActiveRecord::Base.transaction do
        WelcomePageSettings.find.update_attributes!(
          welcome_message: params[:welcome_page_settings][:welcome_message])

        redirect_to edit_admin_welcome_page_settings_path,
          flash: {
            infos: [%(The welcome page settings have been updated.)] }
      end
    end
  end

end
