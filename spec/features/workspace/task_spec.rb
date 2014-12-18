require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Task" do

  scenario "view as public user and signed-in user", 
    browser: :firefox do

    task= Task.first
    repos= task.execution.repositories
    repos.each{|r| r.update_attributes! public_view_permission: false}

    sign_in_as 'normin'
    visit workspace_task_path(task)
    expect(page).to have_content "Properties"
    expect(page).to have_content "Specification"

    sign_out
    expect(page).to have_content "401 Unauthorized"
    repos.each{|r| r.update_attributes! public_view_permission: true}
    visit current_path
    expect(page).not_to have_content "401 Unauthorized"

  end

  scenario "following links to trials", browser: :firefox do
    task= Task.first
    sign_in_as 'normin'

    visit workspace_task_path(task)
    first("a.trial-label").click
    expect(current_path).to match(/workspace\/trials\/\w+/)

    visit workspace_task_path(task)
    first("a .script-label").click
    expect(current_path).to match(/workspace\/trials\/\w+/)
    expect(current_fragment).not_to be_blank
    find("##{current_fragment}")

  end

  scenario "Retrying a task", browser: :firefox do
    execution= Execution.first
    sign_in_as 'normin'
    visit workspace_execution_path(execution)

    find("#tasks").first("a,button",text: "Retry").click
    expect(page).to have_content "retrying"

    expect(Messaging.published_messages.first.first).to \
      be== "task.create-trial"
  end

end


