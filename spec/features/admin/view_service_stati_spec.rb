require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Service stati", browser: :firefox  do
  scenario "View the service stati as admin" do
    sign_in_as 'adam'
    click_on "Administration" 
    click_on "Service stati" 
    expect(page).to have_content "API Service"
  end
end



