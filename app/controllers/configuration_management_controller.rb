#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class ConfigurationManagementController < ApplicationController

  # scary code to enable configuration management
  # the only way to get here is to know the secret_key_base

  before_action :authenticate

  def authenticate
    _username, password = ActionController::HttpAuthentication::Basic \
      .user_name_and_password(request) rescue [nil, nil]
    unless Rails.application.secrets.secret_key_base == password
      render plain: 'unauthorized', status: :unauthorized
    end
  end

  def invoke_ruby
    code = request.body.gets
    render plain: eval(code)
  end

  def invoke_sql
    code = request.body.gets
    res = ActiveRecord::Base.connection.execute code
    render plain: res.to_a.to_s
  end

  def invoke
    case request.content_type.try(:downcase)
    when /application\/ruby/
      invoke_ruby
    when /application\/sql/
      invoke_sql
    else
      render status: 422,
             plain: "Don't know how to process content type '#{request.content_type}'."
    end
  end

end
