
require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Badges" do

  scenario "viewing a medium badge for executing tests",
    browser: :firefox do
    Execution.destroy_all
    Repository.first.update_attributes! name: "TestRepo"
    FactoryGirl.create :executing_execution, 
      tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
      name: "Tests"
    visit "/public/badges/medium/testrepo/master/tests.svg"
    find("svg.execution").has_content? "executing"
  end

  scenario "viewing a medium badge for failed tests",
    browser: :firefox do
    Execution.destroy_all
    Repository.first.update_attributes! name: "TestRepo"
    FactoryGirl.create :failed_execution, 
      tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
      name: "Tests"
    visit "/public/badges/medium/testrepo/master/tests.svg"
    find("svg.execution").has_content? "failed"
  end

  scenario "viewing a medium badge for passed tests",
    browser: :firefox do
    Execution.destroy_all
    Repository.first.update_attributes! name: "TestRepo"
    FactoryGirl.create :passed_execution, 
      tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
      name: "Tests"
    visit "/public/badges/medium/testrepo/master/tests.svg"
    find("svg.execution").has_content? "failed"
  end

  scenario "viewing a medium badge for pending tests",
    browser: :firefox do
    Execution.destroy_all
    Repository.first.update_attributes! name: "TestRepo"
    FactoryGirl.create :pending_execution, 
      tree_id: Branch.find_by(name: 'master').current_commit.tree_id,
      name: "Tests"
    visit "/public/badges/medium/testrepo/master/tests.svg"
    find("svg.execution").has_content? "pending"
  end

  scenario "viewing a medium badge for not existing tests",
    browser: :firefox do
    Execution.destroy_all
    Repository.first.update_attributes! name: "TestRepo"
    visit "/public/badges/medium/testrepo/master/tests.svg"
    find("svg.execution").has_content? "not availabel"
  end



end

