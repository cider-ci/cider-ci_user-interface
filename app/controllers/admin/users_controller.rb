#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Admin::UsersController < AdminController
  include Concerns::ManageEmailAddress

  helper_method :admin_filter?, :user_text_search_filter

  def create
    @user = User.create! params.require(:user).permit!
    redirect_to admin_users_path,
                flash: { successes: ['The user has been created'] }
  end

  def destroy
    User.find(params[:id]).destroy
    redirect_to admin_users_path,
                flash: { successes: ['The user has been deleted'] }
  end

  def index
    @users = User.page(params[:page])
    @users = @users.per(Integer(params[:per_page])) unless params[:per_page].blank?
    @users = @users.where(is_admin: true) if admin_filter?
    if search_term = user_text_search_filter
      # NOTE we include the email addresses; however, the pg parser recognizes
      # emails and does not break them apart: foo@bar.baz  will only be found
      # when the full email address is searched for and not by "foo", or "bar", or baz!
      # http://www.postgresql.org/docs/current/static/textsearch-parsers.html
      search_options = { \
        users: { login: search_term, last_name: search_term,
                 first_name: search_term }, \
        email_addresses: { email_address: search_term } }
      @users = \
        @users.joins('LEFT OUTER JOIN email_addresses
                     ON email_addresses.user_id = users.id'.squish) \
        .basic_search(search_options, false).reorder(:last_name, :first_name).uniq
    end
  end

  def new
    @user = User.new params.permit![:user]
  end

  def show
    @user = User.find params[:id]
  end

  def update
    with_rescue_flash do
      @user = User.find(params[:id])
      @user.update_attributes! params.require(:user).permit!
      { successes: ['The user has been updated.'] }
    end
  end

  def user_text_search_filter
    params.try('[]', 'user').try('[]', :text).presence
  end

  def admin_filter?
    params['is_admin'].present?
  end

  private

  def with_rescue_flash
    flash = begin
             @user = User.find(params[:id])
             yield
           rescue Exception => e
             { errors: [e.to_s] }
           end
    redirect_to admin_user_path(@user), flash: flash
  end

end
