require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Account", browser: :firefox  do

  scenario "Manage email addresses" do
    sign_in_as 'normin'

    find("a#user-actions").click
    click_on("Account")

    find("input#email_address").set "normin1@example.com"
    click_on("Add email address")
    expect(page).to have_content "address has been added"
    expect(page).to have_content "normin1@example.com"

    first("a,button", text: "Set as primary").click
    expect(page).to have_content "A new primary email address has been set."

    find("input#email_address").set "normin2@example.com"
    click_on("Add email address")
    expect(page).to have_content "address has been added"
    expect(page).to have_content "normin2@example.com"

    first("a,button", text: "Remove").click
    expect(page).not_to have_content "normin1@example.com"

  end

  scenario "Change password" do

    sign_in_as 'normin'

    find("a#user-actions").click
    click_on("Account")

    find("input#user_password").set "new-secret"
    click_on("Change")

    expect(page).to have_content "401 Unauthorized"

    find("input[type='text']").set "normin"
    find("input[type='password']").set "new-secret"
    find("button[type='submit']").click
    expect(page).to have_content "been signed in"
    expect(page).not_to have_content "401 Unauthorized"

  end

end



