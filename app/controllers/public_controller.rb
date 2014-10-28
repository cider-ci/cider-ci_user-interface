#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class PublicController < ApplicationController

  include Concerns::ServiceSession
  include Concerns::BadgeParamsBuilder


  def show
    @radiator_rows= 
      begin 
        WelcomePageSettings.find
        .radiator_config.try(:[],"rows").map do |row|
          {name: row.try(:[],"name"),
           items: build_items(row) }
        end
      rescue Exception => e
        Rails.logger.warn ["Failed to parse radiator config",Formatter.exception_to_log_s(e)]
        flash["error"]="Failed to build the radiator, see the logs for details."
        []
      end
  end

  def build_items row
    row.try(:[],"items").map(&:deep_symbolize_keys).map do |item|
      build_badge_params item[:repository_name], item[:branch_name], item[:execution_name]
    end
  end

  def find_user_by_login login
    begin
      User.find_by(login_downcased: login) || EmailAddress.find_by!(email_address: login).user
    rescue
      raise "Neither login nor email found!"
    end
  end


  def sign_in
    begin
      user = find_user_by_login params.require(:sign_in)[:login].downcase
      if user.authenticate(params.require(:sign_in)[:password])
        create_services_session_cookie user
      else
        reset_session
        cookies.delete "cider-ci_services-session"
        raise "Password authentication failed!"
      end
      redirect_to public_path, flash: {success: "You have been signed in!"}
    rescue Exception => e
      reset_session
      cookies.delete "cider-ci_services-session"
      redirect_to public_path, flash: {error: e.to_s}
    end
  end


  def sign_out
    reset_session
    cookies.delete "cider-ci_services-session"
    redirect_to public_path, flash: {success: "You have been signed out!"}
  end

end
