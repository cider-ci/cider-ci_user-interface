require 'cider_ci/open_session/encryptor'
require 'cider_ci/open_session/signature'
require 'chronic_duration'

module Concerns
  module ServiceSession
    extend ActiveSupport::Concern

    def create_services_session_cookie(user)
      unless user.account_enabled
        raise 'This account is disabled!'
      end
      cookies.permanent['cider-ci_services-session'] =
        CiderCi::OpenSession::Encryptor.encrypt(
          secret, user_id: user.id,
                  signature: create_user_signature(user),
                  issued_at: Time.zone.now.iso8601)
    end

    def validate_services_session_cookie_and_get_user
      if session_cookie
        begin
          session_object = CiderCi::OpenSession::Encryptor.decrypt(
            secret, session_cookie).deep_symbolize_keys
          user = User.find session_object[:user_id]
          validate_account_enabled!(user)
          validate_user_signature!(user, session_object[:signature])
          validate_lifetime!(user, session_object)
          user
        rescue Exception => e
          Rails.logger.warn e
          reset_session
          cookies.delete 'cider-ci_services-session'
          nil
        end
      end
    end

    def session_cookie
      @session_cookie ||= cookies['cider-ci_services-session']
    end

    def secret
      Settings[:session][:secret]
    end

    def create_user_signature(user)
      CiderCi::OpenSession::Signature.create \
        secret, user.password_digest.to_s
    end

    def validate_account_enabled!(user)
      unless user.account_enabled
        raise 'This account is not enabled!'
      end
    end

    def validate_user_signature!(user, signature)
      CiderCi::OpenSession::Signature.validate! \
        signature, secret, user.password_digest.to_s
    end

    def validate_lifetime!(user, session_object)
      issued_at = Time.parse(session_object[:issued_at]).in_time_zone
      lifetime = Time.zone.now - issued_at
      validate_lifetime_duration! lifetime, user.max_session_lifetime
      validate_lifetime_duration! lifetime,
        Settings[:session][:max_lifetime].presence || '7 Days'
    end

    def validate_lifetime_duration!(lifetime, duration)
      if duration.present?
        if lifetime > ChronicDuration.parse(duration)
          raise 'The session has expired!'
        end
      end
    end

  end
end
