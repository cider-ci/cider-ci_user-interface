require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Public start page', browser: :firefox  do

  scenario 'automatic redirect from root to public page' do
    visit '/'
    expect(current_path).to be == public_path
  end

  scenario 'public page with not existing / invalid welcome page setting' do
    WelcomePageSettings.find.destroy
    visit public_path
    expect(page).to have_content 'Failed to build the radiator, see the logs for details.'
    expect(page).to have_content 'Markdown render error!'
  end

  scenario 'contains the welcome message and the first svg badge for master' do

    visit '/public'

    expect(page).to have_content 'Welcome to the Cider-CI UI Tests'

    expect(first('svg.badge-medium')).to have_content 'master'

    expect(first('svg.badge-medium')).to have_content 'passed'

  end

  scenario 'redirect for non existing execution',
           browser: :firefox do

    visit '/public/executions/notarepo/master/tests'

    expect(page).to have_content '404 Not found'

  end

  scenario 'public execution redirect to private repo',
           browser: :firefox do

    Repository.find('f182ec87-591a-58bc-b08e-7e83679a4b68') \
      .update_attributes! public_view_permission: false

    visit '/public/executions/Cider-CI%20Bash%20Demo%20Project/master/tests'

    # redirects
    expect(page.current_path).to be == \
      '/workspace/executions/69eedfdb-f4f9-4b6e-b8df-a023df912412'

    # however we are not authorized

    expect(page).to have_content '401 Unauthorized'

  end

  scenario 'public execution redirect for public repo',
           browser: :firefox do

    Repository.find('f182ec87-591a-58bc-b08e-7e83679a4b68') \
      .update_attributes! public_view_permission: true

    visit '/public/executions/Cider-CI%20Bash%20Demo%20Project/master/tests'

    # redirects
    expect(page.current_path).to be == \
      '/workspace/executions/69eedfdb-f4f9-4b6e-b8df-a023df912412'

    expect(page).to have_content 'Execution "Tests"'

  end

end
