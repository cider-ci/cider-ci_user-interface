#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include Concerns::ServiceSession
  include Concerns::SessionHelper


  helper_method :admin_party? ,:current_user, :user?, :users?, :admin?

  before_action do
    Rack::MiniProfiler.authorize_request if session[:mini_profiler_enabled]
  end

  def redirect
    redirect_to public_path
  end

  def admin_party?
    User.admin_party?
  end

  def current_user
    @current_user ||= 
      validate_services_session_cookie_and_get_user rescue nil
  end

  def user? 
    admin_party? or current_user 
  end

  def admin?
    admin_party? or current_user.try(&:is_admin)
  end

  def users?
    User.users?
  end

  # TODO restrict this; otherwise we will have a bunch of dead threads
  def pry
    # binding.pry
  end

end
