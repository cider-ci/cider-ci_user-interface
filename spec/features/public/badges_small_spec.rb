
require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Small Badges' do

  def adjust_data
    Execution.destroy_all
    Repository.first.update_attributes! \
      name: 'TestRepo',
      public_view_permission: true
  end

  scenario 'viewing a small badge for a executing execution',
           browser: :firefox do
    adjust_data
    FactoryGirl.create :executing_execution,
                       tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
                       name: 'Tests'
    visit '/public/badges/small/testrepo/master/tests.svg'
    expect(find('svg.execution-info')).to have_content 'executing'
  end

  scenario 'viewing a small badge for a failed execution',
           browser: :firefox do
    adjust_data
    FactoryGirl.create :failed_execution,
                       tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
                       name: 'Tests'
    visit '/public/badges/small/testrepo/master/tests.svg'
    expect(find('svg.execution-info')).to have_content 'failed'
  end

  scenario 'viewing a small badge for a passed execution',
           browser: :firefox do
    adjust_data
    FactoryGirl.create :passed_execution,
                       tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
                       name: 'Tests'
    visit '/public/badges/small/testrepo/master/tests.svg'
    expect(find('svg.execution-info')).to have_content 'passed'
  end

  scenario 'viewing a small badge for pending tests',
           browser: :firefox do
    adjust_data
    FactoryGirl.create :pending_execution,
                       tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
                       name: 'Tests'
    visit '/public/badges/small/testrepo/master/tests.svg'
    expect(find('svg.execution-info')).to have_content 'pending'
  end

  scenario 'viewing a small badge for a not existing execution',
           browser: :firefox do
    adjust_data
    visit '/public/badges/small/testrepo/master/tests.svg'
    expect(find('svg.execution-info')).to have_content 'Not found'
    expect(find('svg.execution-info')).to have_content 'try again later'
    visit '/public/badges/small/testrepo/master/tests.svg?respond_with_200'
    expect(find('svg.execution-info')).to have_content 'Not found'
    expect(find('svg.execution-info')).to have_content 'try again later'
  end

  scenario 'viewing a small badge for a not public repository',
           browser: :firefox do
    adjust_data
    FactoryGirl.create :passed_execution,
                       tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
                       name: 'Tests'
    Repository.first.update_attributes! public_view_permission: false
    visit '/public/badges/small/testrepo/master/tests.svg'
    expect(find('svg.execution-info')).to have_content 'Forbidden'
    visit '/public/badges/small/testrepo/master/tests.svg?respond_with_200'
    expect(find('svg.execution-info')).to have_content 'Forbidden'
  end

end
