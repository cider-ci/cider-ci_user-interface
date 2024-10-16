#  Copyright (C) 2013 - 2016 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

require "addressable/uri"

class CiderCI::NotAuthorized < StandardError
end

class Public::AuthProviderController < ApplicationController
  include Concerns::HTTP
  include Concerns::AuthProvider::GitHub

  def request_authentication
    case params[:provider]
    when "github"
      github_request_authentication
    end
  end

  def sign_in
    case params[:provider]
    when "github"
      github_sign_in
    end
  rescue CiderCI::NotAuthorized => e
    @message = e.message
    render :not_authorized, status: 401
  rescue Faraday::ClientError => e
    Rails.logger.warn(Formatter.exception_to_log_s(e))
    @message = <<-MSG.strip_heredoc
          An unexpected error happend when communicating
          with the authentication provider. You can try again later.

          Contact your adminstrator if the error persists.
    MSG
    render :provider_error, status: 422
  rescue Exception => e
    Rails.logger.warn(Formatter.exception_to_log_s(e))
    render :unexpected_error, status: 500
  end

  def login(user_properties, config)
    "#{user_properties["login"]}@#{config["name"]}"
  end

  def sync_account(user, sync_data, provider_config)
    email_addresses = sync_data[:email_addresses]
    user = find_user_for_email_addresses(email_addresses) \
      || create_user(sync_data, provider_config)
    create_or_associate_email_addresses_with_user(user, email_addresses)
    user.update(name: sync_data[:name])
    user.update(login: sync_data[:login])
    unless user.password_digest.present?
      user.update!(password: SecureRandom.base64)
    end
    admin_email_addresses = provider_config.accepted_email_addresses.select(&:admin).map(&:email_address).map(&:downcase)
    if user.email_addresses.where("lower(email_address) IN (?)",
                                  admin_email_addresses).first
      user.update!(is_admin: true)
    end
    user
  end

  def create_or_associate_email_addresses_with_user(user, email_addresses)
    email_addresses.each do |em|
      EmailAddress.where("lower(email_address) = ?",
                         em.downcase).first.try do |em|
        em.update!(user: user) if em.user != user
        em
      end || EmailAddress.create(email_address: em, user: user)
    end
  end

  def create_user(sync_data, _provider_config)
    User.create!(login: sync_data[:login])
  end

  def find_user_for_email_addresses(email_addresses)
    User.joins(:email_addresses).where(
      "lower(email_addresses.email_address) IN (?)",
      email_addresses.map(&:downcase)
    ).first
  end

  def get_provider_config(id)
    (Settings[:authentication_providers] || {})[id.to_s]
  end
end
