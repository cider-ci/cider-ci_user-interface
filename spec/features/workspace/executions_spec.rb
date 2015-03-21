require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Browse executions and execution' do

  scenario 'Follow from executions to first execution' do
    sign_in_as 'normin'
    find('a', text: 'Executions').click
    expect(page).to have_content 'Executions'
    expect(current_path).to be == workspace_executions_path
    first('td a', text: 'Tests').click
    expect(page).to have_content 'Execution "Tests"'
    expect(current_path).to be == workspace_execution_path(Execution.find_by(name: 'Tests'))
  end

  scenario 'Use the executions filter' do
    sign_in_as 'normin'
    visit workspace_executions_path
    find('input#repository_names').set 'Cider-CI Bash Demo Project'
    find('input#branch_names').set 'master'
    find('input#execution_tags').set 'adam'
    click_on('Filter')
    expect(all('table#executions-table tbody tr.execution').count).to be == 9

    find('input#execution_tags').set 'asdfasdf'
    click_on('Filter')
    expect(all('table#executions-table tbody tr.execution').count).to be == 0

    find('input#execution_tags').set 'adam'
    click_on('Filter')
    expect(all('table#executions-table tbody tr.execution').count).to be == 9

    find('input#execution_tags').set 'asdfasdf'
    click_on('Filter')
    expect(all('table#executions-table tbody tr.execution').count).to be == 0

    find('input#branch_names').set 'master'
    find('input#repository_names').set 'asdfasdf'
    click_on('Filter')
    expect(all('table#executions-table tbody tr.execution').count).to be == 0

    find('input#repository_names').set 'Cider-CI Bash Demo Project'
    find('input#branch_names').set ''
    find('input#execution_tags').set ''
    click_on('Filter')
    expect(all('table#executions-table tbody tr.execution').count).to be == 9

    # filter by existing tree_id but no execution
    find('input#repository_names').set 'Cider-CI Bash Demo Project'
    find('input#branch_names').set ''
    find('input#execution_tags').set ''
    find('input#tree_id').set '2fdbf4c'
    click_on('Filter')
    expect(all('table#executions-table tbody tr.execution').count).to be == 0

    # filter by existing tree_id with execution
    find('input#repository_names').set 'Cider-CI Bash Demo Project'
    find('input#branch_names').set ''
    find('input#execution_tags').set ''
    find('input#tree_id').set 'b8c74eb'
    click_on('Filter')
    expect(all('table#executions-table tbody tr.execution').count).to be == 1

  end

  scenario 'filter by tree_id' do
    sign_in_as 'normin'
    visit workspace_executions_path
    expect(all('table#executions-table tbody tr.execution').count).to be == 9
    visit workspace_executions_path(tree_id: 'b8c74ebd9260b1a2928767625946b937011a03b6')
    expect(all('table#executions-table tbody tr.execution').count).to be == 1
  end

  scenario 'Suggestions for filter' do
    sign_in_as 'normin'
    visit workspace_executions_path

    find('input#repository_names').set 'Cider'
    expect(find('.ui-autocomplete').text).to have_content 'Cider-CI Bash Demo Project'

    find('input#branch_names').set 'ma'
    expect(find('.ui-autocomplete').text).to have_content 'master'

    find('input#execution_tags').set 'a'
    expect(find('.ui-autocomplete').text).to have_content 'adam'
  end

  scenario 'View execution and tree attachment' do
    skip 'TODO, disabled because of path problems'
    sign_in_as 'normin'
    visit workspace_execution_path(Execution.find_by name: 'Attachments-Demo')
    first('a', text: 'Attachments').click
    find('a', text: 'log/hello.log').click
    expect(page).to have_content 'Attachment /log/hello.log'
    expect(page.text.downcase).to have_content 'content-type:'
  end

  scenario 'View execution specification' do
    sign_in_as 'normin'
    visit workspace_execution_path(Execution.first)
    find('a', text: 'Specification').click
    expect(page).to have_content 'Raw Specification'
    expect(page).to have_content 'Expanded Specification'
  end

end
