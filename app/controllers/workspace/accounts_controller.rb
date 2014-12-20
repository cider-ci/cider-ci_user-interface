#  Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::AccountsController < WorkspaceController
  include Concerns::ManageEmailAddress

  def edit
    @user = current_user
  end

  def update
    with_rescue_flash do
      @user.update_attributes! params.require(:user).permit(:login,:last_name,:first_name,:password)
      {success: "The user has been updated."}
    end
  end


  private

  def with_rescue_flash
    flash= begin 
             @user = current_user
             yield
           rescue Exception => e
             {error: e.to_s}
           end
    redirect_to edit_workspace_account_path, flash: flash
  end


end
