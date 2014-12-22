require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Sign-in" do

  scenario "Sign-in", browser: :firefox  do

    visit "/public"

    sign_in_as 'normin'

    expect(page).to have_content "been signed in"
    expect(page).to have_content "normin"

    sign_out

    expect(page).to have_content "been signed out"
    expect(page).not_to have_content "normin"

  end

  scenario "Sign-in with wrong password ", 
    browser: :firefox  do
    visit "/public" unless current_path 
    find("input[type='text']").set "normin"
    find("input[type='password']").set "bogus password"
    find("button[type='submit']").click
    expect(page).to have_content "authentication failed"
  end

  scenario "Sign-in with wrong login", 
    browser: :firefox  do
    visit "/public" unless current_path 
    find("input[type='text']").set "norminx"
    find("input[type='password']").set "password"
    find("button[type='submit']").click
    expect(page).to have_content "Neither login nor email address found"
  end

  scenario "Set email and sign in by email", 
    browser: :firefox  do
    sign_in_as 'normin'
    find("a#user-actions").click
    click_on("Account")
    find("input#email_address").set "normin@example.com"
    click_on("Add email address")
    expect(page).to have_content "address has been added"
    sign_out
    expect(page).to have_content "401 Unauthorized"
    find("input[type='text']").set "normin@example.com"
    find("input[type='password']").set "password"
    find("button[type='submit']").click
    expect(page).to have_content "been signed in"
  end

end
