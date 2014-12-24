require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Browse executions and execution' do

  scenario 'Follow from executions to first execution',
           browser: :firefox  do
    sign_in_as 'normin'
    find('a', text: 'Executions').click
    expect(page).to have_content 'Executions'
    expect(current_path).to be == workspace_executions_path
    first('td a').click
    expect(page).to have_content 'Execution "Tests"'
    expect(current_path).to be == workspace_execution_path(Execution.first)
  end

  scenario 'Use the executions filter',
           browser: :firefox  do
    sign_in_as 'normin'
    visit workspace_executions_path
    find('input#repository_names').set 'Cider-CI Bash Demo Project'
    find('input#branch_names').set 'master'
    find('input#execution_tags').set 'adam'
    submit_form
    expect(all('table#executions-table tbody tr.execution').count).to be == 1
    find('input#execution_tags').set 'asdfasdf'
    submit_form
    expect(all('table#executions-table tbody tr.execution').count).to be == 0
    find('input#execution_tags').set 'adam'
    find('input#branch_names').set 'asdfasdf'
    submit_form
    expect(all('table#executions-table tbody tr.execution').count).to be == 0
    find('input#branch_names').set 'master'
    find('input#repository_names').set 'asdfasdf'
    submit_form
    expect(all('table#executions-table tbody tr.execution').count).to be == 0
    find('input#repository_names').set 'Cider-CI Bash Demo Project'
    submit_form
    expect(all('table#executions-table tbody tr.execution').count).to be == 1
  end

  scenario 'Suggestions for filter',
           browser: :firefox  do
    sign_in_as 'normin'
    visit workspace_executions_path

    find('input#repository_names').set 'Cider'
    expect(find('.ui-autocomplete').text).to have_content 'Cider-CI Bash Demo Project'

    find('input#branch_names').set 'ma'
    expect(find('.ui-autocomplete').text).to have_content 'master'

    find('input#execution_tags').set 'a'
    expect(find('.ui-autocomplete').text).to have_content 'adam'
  end

  scenario 'View execution and tree attachment',
           browser: :firefox do
    sign_in_as 'normin'
    visit workspace_execution_path(Execution.first)
    find('a', text: 'Attachments').click
    find('a', text: 'log/hello.log').click
    expect(page).to have_content 'Attachment /log/hello.log'
    expect(page.text.downcase).to have_content 'content-type:'
  end

  scenario 'View execution specification',
           browser: :firefox do
    sign_in_as 'normin'
    visit workspace_execution_path(Execution.first)
    find('a', text: 'Specification').click
    expect(page).to have_content 'Raw Specification'
    expect(page).to have_content 'Expanded Specification'
  end

end
