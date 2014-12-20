require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Managing time and timeout settings ", browser: :firefox  do

  scenario "Browsing to the execution definition page" do
    sign_in_as 'adam'
    click_on "Administration" 
    click_on "Welcome" 

    find("textarea#welcome_page_settings_welcome_message").set ("# Hello Test!")

    find("textarea#welcome_page_settings_radiator_config_yaml").set(
      {rows: {items: "Bogus!"}}.to_yaml) 

    click_on "Save"

    expect(page).to have_content "updated"

    visit public_path

    find("h1",text: "Hello Test!")

    expect(page).to have_content "Failed to build the radiator, see the logs for details."
  end

end
