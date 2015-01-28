require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Browse execution' do

  scenario 'View execution and tree attachment' do
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

  scenario 'Edit execution ' do
    sign_in_as 'normin'
    visit workspace_execution_path(Execution.first)
    find('a', text: 'Edit').click
    find('input#execution_tags').set 'footag, bartag'
    find("input[name='execution[priority]']").set 9
    submit_form
    expect(page).to have_content 'footag'
  end

  scenario 'Retry failed tasks' do
    Execution.destroy_all
    FactoryGirl.create :failed_execution
    sign_in_as 'normin'
    visit workspace_execution_path(Execution.first)
    find('button,a', text: 'Retry failed').click
    expect(page).to have_content 'failed tasks are scheduled for retry'
    expect(Messaging.published_messages.last.first).to be == 'task.create-trial'
  end

  scenario 'Delete execution' do
    sign_in_as 'adam'
    visit workspace_execution_path(Execution.first)
    find('button,a', text: 'Delete').click
    expect(page).to have_content 'has been deleted'
    expect(current_path).to be == workspace_commits_path
  end

  scenario 'Create a execution' do
    Execution.destroy_all
    FactoryGirl.create :definition
    sign_in_as 'normin'
    visit workspace_commits_path
    first('button,a', text: 'Execute').click
    find("input[name='execution[tags]']").set 'foobartag'
    submit_form
    expect(page).to have_content 'execution has been created'
    expect(page).to have_content 'foobartag'
    expect(current_path).to be == workspace_execution_path(Execution.first)
    expect(Messaging.published_messages.last.first).to  \
      be == 'execution.create-tasks-and-trials'
  end

  scenario 'View and dismiss an execution issue' do
    Execution.destroy_all
    FactoryGirl.create :execution_with_issue
    issue_description = ExecutionIssue.first.description
    sign_in_as 'normin'
    visit workspace_execution_path(Execution.first)
    expect(page).to have_content 'execution has issue'
    find('a', text: 'Issue').click
    expect(page).to have_content issue_description
    find('a,button', text: 'Dismiss').click
    expect(page).not_to have_content issue_description
    click_link('Execution', exact: true)
    expect(current_path).to be == workspace_execution_path(Execution.first)
  end

end
