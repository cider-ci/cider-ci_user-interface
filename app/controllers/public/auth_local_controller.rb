#  Copyright (C) 2013 - 2016 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Public::AuthLocalController < ApplicationController
  def find_user_by_login!
    login = params.require(:sign_in)[:login].downcase
    error_msg = "Neither login nor email address found!"
    begin
      User.where("lower(login) = lower(?)", login).first ||
        EmailAddress.where("lower(email_address) = lower(?)", login).first.user ||
        raise(error_msg)
    rescue
      raise error_msg
    end
  end

  def current_path
    params[:current_fullpath] || public_path
  end

  def sign_in
    user = find_user_by_login!
    unless user.password_sign_in_allowed
      raise "Password authentication is not allowed for this account!"
    end
    if user.authenticate(params.require(:sign_in)[:password])
      create_services_session_cookie user
      post_sign_in_path = if current_path == "/cider-ci/ui/public"
          workspace_filter_path
        else
          current_path
        end
      redirect_to post_sign_in_path,
        flash: { successes: ["You have been signed in!"] }
    else
      reset_session
      cookies.delete "cider-ci_services-session"
      raise "Password authentication failed!"
    end
  rescue Exception => e
    reset_session
    cookies.delete "cider-ci_services-session"
    redirect_to (current_path || public_path), flash: { errors: [e.to_s] }
  end
end
