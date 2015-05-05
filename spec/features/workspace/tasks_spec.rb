require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Tasks' do

  def shown_tasks_states
    all('.task').map { |e| e['data-state'] }.uniq.sort
  end

  scenario 'Filter tasks from job show action by state' do

    Job.destroy_all
    FactoryGirl.create :failed_job

    sign_in_as 'normin'
    visit workspace_job_path(Job.first)

    find('select#tasks_select_condition').select('All')
    click_on('Filter')
    expect(shown_tasks_states).to be == %w(executing failed passed pending)

    find('select#tasks_select_condition').select('Failed')
    click_on('Filter')
    expect(shown_tasks_states).to be == ['failed']

    find('select#tasks_select_condition').select('Unpassed')
    click_on('Filter')
    expect(shown_tasks_states).to be == %w(executing failed pending)

    find('select#tasks_select_condition').select('With failed trials')
    click_on('Filter')
    expect(shown_tasks_states).to be == ['failed']

  end

  scenario 'Filter tasks from job show action by name' do

    sign_in_as 'normin'
    visit workspace_job_path(Job.find_by(name: 'All'))

    find('select#tasks_select_condition').select('All')
    click_on('Filter')

    expect(all('.task').count).to be >= 10

    find('input#name_substring_term').set('Attachments OR Port')
    click_on('Filter')

    expect(all('.task').count).to be == 2
    expect(page).to have_content 'Attachments'
    expect(page).to have_content 'Port'

  end

end
