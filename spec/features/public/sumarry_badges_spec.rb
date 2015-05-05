require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Summary Badges' do

  def adjust_data
    Job.destroy_all
    Repository.first.update_attributes! \
      name: 'TestRepo',
      public_view_permission: true
  end

  scenario 'viewing a summary badge for a executing job' do
    adjust_data
    FactoryGirl.create :executing_job,
                       tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
                       name: 'Tests'
    visit '/public/testrepo/master/tests/summary.svg'
    expect(find('svg.job-info')).to have_content 'executing'
  end

  scenario 'viewing a summary badge for a executing with result' do
    adjust_data
    FactoryGirl.create :job_with_result,
                       tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
                       name: 'Tests'
    visit '/public/testrepo/master/tests/summary.svg'
    expect(find('svg.job-info')).to have_content '42 OK'
  end

  scenario 'viewing a summary badge for a failed job' do
    adjust_data
    FactoryGirl.create :failed_job,
                       tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
                       name: 'Tests'
    visit '/public/testrepo/master/tests/summary.svg'
    expect(find('svg.job-info')).to have_content 'failed'
  end

  scenario 'viewing a summary badge for a passed job' do
    adjust_data
    FactoryGirl.create :passed_job,
                       tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
                       name: 'Tests'
    visit '/public/testrepo/master/tests/summary.svg'
    expect(find('svg.job-info')).to have_content 'passed'
  end

  scenario 'viewing a summary badge for pending tests' do
    adjust_data
    FactoryGirl.create :pending_job,
                       tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
                       name: 'Tests'
    visit '/public/testrepo/master/tests/summary.svg'
    expect(find('svg.job-info')).to have_content 'pending'
  end

  scenario 'viewing a summary badge for a not existing repository' do
    adjust_data
    visit '/public/NOREPO/NOBRANCH/tests/summary.svg'
    expect(first('svg')).to have_content 'Not found'
    visit '/public/NOREPO/NOBRANCH/tests/summary.svg?respond_with_200'
    expect(first('svg')).to have_content 'Not found'
  end

  scenario 'viewing a summary badge for a not existing branch' do
    adjust_data
    visit '/public/testrepo/NOBRANCH/tests/summary.svg'
    expect(first('svg')).to have_content 'Not found'
    visit '/public/testrepo/NOBRANCH/tests/summary.svg?respond_with_200'
    expect(first('svg')).to have_content 'Not found'
  end

  scenario 'viewing a summary badge for a not existing job' do
    adjust_data
    visit '/public/testrepo/master/tests/summary.svg'
    expect(first('svg')).to have_content 'Not available'
    visit '/public/testrepo/master/tests/summary.svg?respond_with_200'
    expect(first('svg')).to have_content 'Not available'
  end

  scenario 'viewing a summary badge for a not public repository' do
    adjust_data
    FactoryGirl.create :passed_job,
                       tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
                       name: 'Tests'
    Repository.first.update_attributes! public_view_permission: false
    visit '/public/testrepo/master/tests/summary.svg'
    expect(first('svg')).to have_content 'Forbidden'
    visit '/public/testrepo/master/tests/summary.svg?respond_with_200'
    expect(first('svg')).to have_content 'Forbidden'
  end

end
