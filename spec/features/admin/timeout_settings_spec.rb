require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Managing time and timeout settings ', browser: :firefox  do

  scenario 'Browsing to the execution definition page' do
    sign_in_as 'adam'
    click_on 'Administration'
    click_on 'Time'
    find('input#timeout_settings_trial_scripts_retention_time_days').set 17
    click_on 'Save'
    expect(page).to have_content 'updated'
  end

end
