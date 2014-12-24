#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  include Concerns::ServiceSession
  include Concerns::SessionHelper

  helper_method :current_user, :user?, :users?, :admin?

  before_action do
    @alerts ||= { errors: (flash[:errors] || []),
                  infos: (flash[:infos] || []),
                  successes: (flash[:successes] || []),
                  warnings: (flash[:warnings] || []) }
  end

  before_action do
    Rack::MiniProfiler.authorize_request if session[:mini_profiler_enabled]
  end

  def redirect
    redirect_to public_path
  end

  def current_user
    @current_user ||=
      validate_services_session_cookie_and_get_user rescue nil
  end

  def user?
    current_user
  end

  def admin?
    current_user.try(&:is_admin)
  end

  def render_404(msg = nil)
    @alerts[:warnings] << msg if msg
    render 'public/404', status: 404
  end

end
