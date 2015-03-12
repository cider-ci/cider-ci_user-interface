require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Managing Executors as Admin ', browser: :firefox  do

  scenario 'Browsing to the executors page' do
    sign_in_as 'adam'
    click_on 'Administration'
    click_on 'Executors'
    expect(current_path).to be == admin_executors_path
  end

  scenario 'Creating a new executor'  do
    Executor.destroy_all
    sign_in_as 'adam'
    visit admin_executors_path
    click_on 'Add a new executor'
    find('input#executor_name').set 'Executor1'
    find('input#executor_base_url').set 'http://localhost:8883'
    click_on 'Create'
    expect(page).to have_content 'has been created'
    expect(page).to have_content 'Executor1'
  end

  scenario 'Editing a executor' do
    sign_in_as 'adam'
    visit admin_executors_path
    first('a,button', text: 'Show more').click
    first('a,button', text: 'Edit').click
    find('input#executor_name').set 'NewExecutorName'
    click_on('Save')
    expect(page).to have_content 'been updated'
    expect(page).to have_content 'NewExecutorName'
  end

  scenario 'Deleting a executor' do
    executors_count = Executor.count
    sign_in_as 'adam'
    visit admin_executors_path
    first('a,button', text: 'Show more').click
    first('a,button', text: 'Delete').click
    expect(page).to have_content 'been deleted'
    expect(Executor.count).to be == executors_count - 1
  end

end
