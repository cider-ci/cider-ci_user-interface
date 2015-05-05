require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Browse job' do

  scenario 'View job and tree attachment' do
    skip 'TODO; temporarily disabled because of path problem'
    sign_in_as 'normin'
    visit workspace_job_path(Job.find_by name: 'Attachments-Demo')
    first('a', text: 'Attachments').click
    find('a', text: 'log/hello.log').click
    expect(page).to have_content 'Attachment /log/hello.log'
    expect(page.text.downcase).to have_content 'content-type:'
  end

  scenario 'View job job_specification' do
    sign_in_as 'normin'
    visit workspace_job_path(Job.first)
    find('a', text: 'JobSpecification').click
    expect(page).to have_content 'Raw JobSpecification'
    expect(page).to have_content 'Expanded JobSpecification'
  end

  scenario 'Edit job ' do
    sign_in_as 'normin'
    visit workspace_job_path(Job.first)
    find('a', text: 'Edit').click
    find('input#job_tags').set 'footag, bartag'
    find("input[name='job[priority]']").set 9
    submit_form
    expect(page).to have_content 'footag'
  end

  scenario 'Retry failed tasks' do
    Job.destroy_all
    FactoryGirl.create :failed_job
    sign_in_as 'normin'
    visit workspace_job_path(Job.first)
    find('button,a', text: 'Retry failed').click
    expect(page).to have_content 'failed tasks are scheduled for retry'
    expect(Messaging.published_messages.last.first).to be == 'task.create-trial'
  end

  scenario 'Delete job' do
    sign_in_as 'adam'
    visit workspace_job_path(Job.first)
    find('button,a', text: 'Delete').click
    expect(page).to have_content 'has been deleted'
    expect(current_path).to be == workspace_commits_path
  end

  scenario 'Create a job' do
    skip 'TODO move to full integration tests'
    Job.destroy_all
    FactoryGirl.create :definition
    sign_in_as 'normin'
    visit workspace_commits_path
    find('select#commited_within_last_days').select('10 years')
    click_on('Filter')
    first('button,a', text: 'Run').click
    first("input[name='job[tags]']").set 'foobartag'
    submit_form
    expect(page).to have_content 'job has been created'
    expect(page).to have_content 'foobartag'
    expect(current_path).to be == workspace_job_path(Job.first)
    expect(Messaging.published_messages.last.first).to  \
      be == 'job.create-tasks-and-trials'
  end

  scenario 'View and dismiss an job issue' do
    Job.destroy_all
    FactoryGirl.create :job_with_issue
    issue_description = JobIssue.first.description
    sign_in_as 'normin'
    visit workspace_job_path(Job.first)
    expect(page.text).to match /job has .+ issue/
    find('a', text: 'Issue').click
    expect(page).to have_content issue_description
    find('a,button', text: 'Dismiss').click
    expect(page).not_to have_content issue_description
    click_link('Job', exact: true)
    expect(current_path).to be == workspace_job_path(Job.first)
  end

end
