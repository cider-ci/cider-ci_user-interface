require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Browse jobs and job' do

  scenario 'Follow from jobs to first job' do
    sign_in_as 'normin'
    find('a', text: 'Jobs').click
    expect(page).to have_content 'Jobs'
    expect(current_path).to be == workspace_jobs_path
    first('td a', text: 'Tests').click
    expect(page).to have_content 'Job "Tests"'
    expect(current_path).to be == workspace_job_path(Job.find_by(name: 'Tests'))
  end

  scenario 'Use the jobs filter' do
    sign_in_as 'normin'
    visit workspace_jobs_path
    find('input#repository_names').set 'Cider-CI Bash Demo Project'
    find('input#branch_names').set 'master'
    find('input#job_tags').set 'adam'
    click_on('Filter')
    expect(all('table#jobs-table tbody tr.job').count).to be == 9

    find('input#job_tags').set 'asdfasdf'
    click_on('Filter')
    expect(all('table#jobs-table tbody tr.job').count).to be == 0

    find('input#job_tags').set 'adam'
    click_on('Filter')
    expect(all('table#jobs-table tbody tr.job').count).to be == 9

    find('input#job_tags').set 'asdfasdf'
    click_on('Filter')
    expect(all('table#jobs-table tbody tr.job').count).to be == 0

    find('input#branch_names').set 'master'
    find('input#repository_names').set 'asdfasdf'
    click_on('Filter')
    expect(all('table#jobs-table tbody tr.job').count).to be == 0

    find('input#repository_names').set 'Cider-CI Bash Demo Project'
    find('input#branch_names').set ''
    find('input#job_tags').set ''
    click_on('Filter')
    expect(all('table#jobs-table tbody tr.job').count).to be == 9

    # filter by existing tree_id but no job
    find('input#repository_names').set 'Cider-CI Bash Demo Project'
    find('input#branch_names').set ''
    find('input#job_tags').set ''
    find('input#tree_id').set '2fdbf4c'
    click_on('Filter')
    expect(all('table#jobs-table tbody tr.job').count).to be == 0

    # filter by existing tree_id with job
    find('input#repository_names').set 'Cider-CI Bash Demo Project'
    find('input#branch_names').set ''
    find('input#job_tags').set ''
    find('input#tree_id').set 'b8c74eb'
    click_on('Filter')
    expect(all('table#jobs-table tbody tr.job').count).to be == 1

  end

  scenario 'filter by tree_id' do
    sign_in_as 'normin'
    visit workspace_jobs_path
    expect(all('table#jobs-table tbody tr.job').count).to be == 9
    visit workspace_jobs_path(tree_id: 'b8c74ebd9260b1a2928767625946b937011a03b6')
    expect(all('table#jobs-table tbody tr.job').count).to be == 1
  end

  scenario 'Suggestions for filter' do
    sign_in_as 'normin'
    visit workspace_jobs_path

    find('input#repository_names').set 'Cider'
    expect(find('.ui-autocomplete').text).to have_content 'Cider-CI Bash Demo Project'

    find('input#branch_names').set 'ma'
    expect(find('.ui-autocomplete').text).to have_content 'master'

    find('input#job_tags').set 'a'
    expect(find('.ui-autocomplete').text).to have_content 'adam'
  end

  scenario 'View job and tree attachment' do
    skip 'TODO, disabled because of path problems'
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

end
