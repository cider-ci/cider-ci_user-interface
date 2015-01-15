# disabled since this need the repo service
require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'execution definitions in dot-file .cider-ci.yml' do

  scenario 'various warnings and errors, and a working example' do

    sign_in_as 'normin'

    visit workspace_commits_path
    find('select#commited_within_last_days').select('10 years')
    find('input#commit_text').set('Wrong cider-ci dotfile extension')
    click_on('Filter')
    click_on('Execute')
    expect(page).to have_content 'there is no cider-ci dot-file for this commit'

    visit workspace_commits_path
    find('select#commited_within_last_days').select('10 years')
    find('input#commit_text').set('Syntax error in cider-ci dotfile')
    click_on('Filter')
    click_on('Execute')
    expect(page).to have_content 'There is a syntax error in the cider-ci dot-file'

    visit new_workspace_execution_path(
      commit_id: 'eb30be40a2d581b5872b087a8ee34d4913f9bf0f')
    expect(page.text).to match /The cider-ci dot-file .* is empty/

    visit workspace_commits_path
    find('select#commited_within_last_days').select('10 years')
    find('input#commit_text').set('Empty executions in cider-ci dotfile')
    click_on('Filter')
    click_on('Execute')
    expect(page.text).to match \
      /.*executions. property in the cider-ci dot-file .* is not present or empty/

    visit workspace_commits_path
    find('select#commited_within_last_days').select('10 years')
    find('input#commit_text').set('Bogus executions structure in cider-ci dotfile')
    click_on('Filter')
    click_on('Execute')
    expect(page.text).to match /An error occurred while processing/

    visit workspace_commits_path
    find('select#commited_within_last_days').select('10 years')
    find('input#commit_text').set('Working cider-ci dotfile with Tests execution')
    click_on('Filter')
    click_on('Execute')
    submit_form
    expect(current_path).to be == workspace_execution_path(Execution.first)
    expect(page).to have_content 'execution has been created'

  end

end
