require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Task' do

  scenario 'view as public user and signed-in user' do

    task = Task.first
    repos = task.execution.repositories
    repos.each { |r| r.update_attributes! public_view_permission: false }

    sign_in_as 'normin'
    visit workspace_task_path(task)
    expect(page).to have_content 'Properties'
    expect(page).to have_content 'Specification'

    sign_out
    expect(page).to have_content '401 Unauthorized'
    repos.each { |r| r.update_attributes! public_view_permission: true }
    visit current_path
    expect(page).not_to have_content '401 Unauthorized'

  end

  scenario 'following links to trials' do
    task = Task.first
    sign_in_as 'normin'

    visit workspace_task_path(task)
    first('a.trial-label').click
    expect(current_path).to match(%r{workspace/trials/\w+})

    visit workspace_task_path(task)
    first('a .script-label').click
    expect(current_path).to match(%r{workspace/trials/\w+})
    expect(current_fragment).not_to be_blank
    find("##{current_fragment}")

  end

  scenario 'Retrying a task' do
    execution = Execution.first
    sign_in_as 'normin'
    visit workspace_execution_path(execution)

    find('select#tasks_select_condition').select('All')
    click_on('Filter')

    find('#tasks').first('a,button', text: 'Retry').click
    expect(page).to have_content 'retrying'

    expect(Messaging.published_messages.first.first).to \
      be == 'task.create-trial'
  end

  scenario 'View and dismiss an execution issue' do
    Execution.destroy_all
    FactoryGirl.create :execution_with_issue
    sign_in_as 'normin'
    visit workspace_execution_path(Execution.first)
    find('li.trial a').click
    expect(page.text).to match /trial has .+ issue/
    find('a', text: 'Issue').click
    find('.issue.panel') # there is a issue panel
    find('a,button', text: 'Dismiss').click
    expect(all('.issue.panel')).to be_empty
  end

end
