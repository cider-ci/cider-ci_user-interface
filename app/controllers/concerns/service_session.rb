
module Concerns
  module ServiceSession 
    extend ActiveSupport::Concern

    def create_services_session_cookie user
      message= Base64.encode64(user.id).strip
      signature= compute_signature(message, user.password_digest)
      cookie_value= [message,signature].join("-")
      cookies.permanent["cider-ci_services-session"]= cookie_value
    end

    def validate_services_session_cookie_and_get_user
      unless session_cookie= cookies["cider-ci_services-session"]
        nil
      else
        begin
          message, challenge = session_cookie.split("-")
          user_id= Base64.decode64(message)
          user = User.find user_id
          signature= compute_signature(message, user.password_digest)
          if signature == challenge
            user
          else
            raise "Signature is invalid" if signature != cookie_sig
          end
        rescue Exception => e
          Rails.logger.warn e
          reset_session
          cookies.delete "cider-ci_services-session"
          nil
        end
      end
    end

    def compute_signature message, secret1, secret2 = Rails.application.secrets.secret_key_base
      digest = OpenSSL::Digest.new('sha1')
      intermediate= OpenSSL::HMAC.hexdigest(digest, secret1, message)
      final_signature= OpenSSL::HMAC.hexdigest(digest, secret2, intermediate)
    end

  end
end

