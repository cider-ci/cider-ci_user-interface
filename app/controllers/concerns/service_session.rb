require 'cider_ci/open_session/encryptor'
require 'cider_ci/open_session/signature'

module Concerns
  module ServiceSession
    extend ActiveSupport::Concern

    def create_services_session_cookie(user)
      cookies.permanent['cider-ci_services-session'] =
        CiderCi::OpenSession::Encryptor.encrypt(
          secret, user_id: user.id,
                  signature: create_user_signature(user),
                  issued_at: Time.zone.now.iso8601)
    end

    def validate_services_session_cookie_and_get_user
      begin
        session_object = CiderCi::OpenSession::Encryptor.decrypt(
          secret, session_cookie).deep_symbolize_keys
        user = User.find session_object[:user_id]
        validate_user_signature!(user, session_object[:signature])
        user
      rescue Exception => e
        Rails.logger.info e
        reset_session
        cookies.delete 'cider-ci_services-session'
        nil
      end
    end

    def session_cookie
      cookies['cider-ci_services-session'] || raise('Service cookie not found.')
    end

    def secret
      Rails.application.secrets.secret_key_base
    end

    def create_user_signature(user)
      CiderCi::OpenSession::Signature.create \
        secret, user.password_digest
    end

    def validate_user_signature!(user, signature)
      CiderCi::OpenSession::Signature.validate! \
        signature, secret, user.password_digest
    end

  end
end
