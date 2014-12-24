require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Account', browser: :firefox  do

  scenario 'Edit the session parameters' do

    sign_in_as 'normin'

    find('a#user-actions').click
    click_on('Session')

    expect(find('input#mini_profiler_enabled')).not_to be_checked
    find('input#mini_profiler_enabled').set(true)
    expect(find('input#mini_profiler_enabled')).to be_checked

    expect(find('select#reload_strategy').value).to be == 'default'
    find('select#reload_strategy').select('Disabled')
    expect(find('select#reload_strategy').value).to be == 'disabled'

    expect(find('select#reload_frequency').value).to be == 'default'
    find('select#reload_frequency').select('Aggressive')
    expect(find('select#reload_frequency').value).to be == 'aggressive'

    click_on 'Save'
    expect(page).to have_content('The session parameters have been set')

    visit workspace_executions_path
    visit edit_workspace_session_path

    expect(find('input#mini_profiler_enabled')).to be_checked
    expect(find('select#reload_strategy').value).to be == 'disabled'
    expect(find('select#reload_frequency').value).to be == 'aggressive'

    find('select#reload_frequency').select('Slow')
    expect(find('select#reload_frequency').value).to be == 'slow'

    click_on 'Save'
    expect(page).to have_content('The session parameters have been set')

    visit workspace_executions_path
    visit edit_workspace_session_path

    expect(find('select#reload_frequency').value).to be == 'slow'

  end

end
