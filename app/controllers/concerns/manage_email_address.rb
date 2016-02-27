module Concerns
  module ManageEmailAddress
    extend ActiveSupport::Concern

    # email
    def as_primary_email_address
      with_rescue_flash do
        EmailAddress.where(user_id: @user.id).update_all primary: false
        EmailAddress.find_by(user_id: @user.id,
                             email_address: params[:email_address])\
          .update_attributes! primary: true
        { successes: ['A new primary email address has been set.'] }
      end
    end

    def add_email_address
      with_rescue_flash do
        EmailAddress.create! user_id: @user.id,
                             email_address: params[:email_address]
        { successes: ['The new email address has been added.'] }
      end
    end

    def delete_email_address
      with_rescue_flash do
        EmailAddress.find_by(user_id: @user.id,
                             email_address: params[:email_address]).destroy
        { successes: ['The email address has been removed.'] }
      end
    end

  end
end
