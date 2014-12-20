require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Managing users as admin ", browser: :firefox  do

  scenario "Browsing to the users page" do
    sign_in_as 'adam'
    click_on "Administration" 
    click_on "Users" 
    expect(current_path).to be== admin_users_path

    expect(page).to have_content "Normin"
    expect(page).to have_content "Adam"

    find("input#is_admin").set(true)
    click_on("Filter")

    expect(page).not_to have_content "Normin"
    expect(page).to have_content "Adam"

    find("input#is_admin").set(false)
    find("input#user_text").set("Normin")
    click_on("Filter")

    expect(page).to have_content "Normin"
    expect(find("#users")).not_to have_content "Adam"


  end

  scenario "Create a user, and log in as that one" do
    sign_in_as 'adam'
    visit admin_users_path
    click_on 'Add a new user'
    find("input#user_login").set "joe"
    find("input#user_first_name").set "Joe"
    find("input#user_last_name").set "Developer"
    find("input#user_password").set "secret"
    click_on 'Create'
    expect(page).to have_content 'created'
    sign_out 
    visit public_path
    sign_in_as "joe", "wrong-secret"
    expect(page).to have_content "authentication failed"
    sign_in_as "joe", "secret"
    expect(page).to have_content "signed in"
  end

  scenario "Edit a user" do
    sign_in_as 'adam'
    visit admin_users_path
    click_on 'Normin'
    find("input#user_last_name").set "Normalus"
    click_on 'Save'
    expect(page).to have_content 'updated'
    expect(User.find_by(login: 'normin').last_name).to be== "Normalus"
  end

  scenario "Delete a user" do
    users_count= User.count
    sign_in_as 'adam'
    visit admin_users_path
    click_on 'Normin'
    click_on 'Delete'
    expect(User.count).to be== users_count - 1
  end

end

