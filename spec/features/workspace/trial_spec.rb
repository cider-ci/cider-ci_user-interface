require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Trial' do

  scenario 'view trial as public user and signed-in user' do

    trial = Trial.first
    repos = trial.task.job.repositories
    repos.each { |r| r.update_attributes! public_view_permission: false }

    visit workspace_trial_path(trial)

    expect(page).to have_content '401 Unauthorized'
    expect(page).not_to have_content 'Trial for the task'

    sign_in_as 'normin'
    expect(page).not_to have_content '401 Unauthorized'
    expect(page).to have_content 'Trial for the task'

    repos.each { |r| r.update_attributes! public_view_permission: true }
    sign_out
    expect(page).not_to have_content '401 Unauthorized'
    expect(page).to have_content 'Trial for the task'

  end

  scenario 'View attachment' do

    skip 'TODO disabled because of path problems'

    attachment = TrialAttachment.first
    trial_id = attachment.path.split('/').second
    trial = Trial.find(trial_id)
    repos = trial.task.job.repositories
    repos.each { |r| r.update_attributes! public_view_permission: false }

    sign_in_as 'normin'
    visit workspace_trial_path(trial_id)

    click_on('Attachments')
    click_on('/log/hello.log')
    expect(page).to have_content 'Attachment /log/hello.log'
    expect(page.text.downcase).to have_content 'content-type:'

    sign_out
    expect(page).to have_content '401 Unauthorized'
    repos.each { |r| r.update_attributes! public_view_permission: true }
    visit current_path
    expect(page).not_to have_content '401 Unauthorized'

  end

  scenario 'View and dismiss a trial issue' do
    Job.destroy_all
    FactoryGirl.create :job_with_issue
    sign_in_as 'normin'
    visit workspace_job_path(Job.first)

  end

end
