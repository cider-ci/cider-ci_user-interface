#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  include Concerns::ServiceSession
  include Concerns::SessionHelper
  include Concerns::UrlBuilder

  helper_method :current_user, :user?, :users?, :admin?, :api_browser_path

  before_action do
    @alerts ||= { errors: (flash[:errors] || []),
                  infos: (flash[:infos] || []),
                  successes: (flash[:successes] || []),
                  warnings: (flash[:warnings] || []) }
  end

  before_action do
    if defined?(Rack::MiniProfiler)
      if current_user && current_user.mini_profiler_is_enabled
        Rack::MiniProfiler.authorize_request
      else
        Rack::MiniProfiler.deauthorize_request
      end
    end
  end

  def redirect
    if current_user

      redirect_to workspace_path(user_workspace_filter)
    else
      redirect_to public_path
    end
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

  def user_workspace_filter
    current_user.try(:workspace_filters) || {}
  end

  def status
    memory_status = Status::Memory.status
    render json: { memory: memory_status.content }, status: memory_status.is_ok ? 200 : 499
  end

end
