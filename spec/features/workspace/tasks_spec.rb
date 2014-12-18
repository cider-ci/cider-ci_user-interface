require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Tasks" do

  def shown_tasks_states 
    all(".task").map{|e| e['data-state']}.uniq.sort
  end

  scenario "Filter tasks from execution show action by state", 
    browser: :firefox  do

    Execution.destroy_all
    FactoryGirl.create :failed_execution

    sign_in_as 'normin'
    visit workspace_execution_path(Execution.first)

    find("select#tasks_select_condition").select("All")
    click_on("Filter")
    expect(shown_tasks_states).to be== ["executing", "failed", "passed", "pending"]

    find("select#tasks_select_condition").select("Failed")
    click_on("Filter")
    expect(shown_tasks_states).to be== ["failed"]

    find("select#tasks_select_condition").select("Unpassed")
    click_on("Filter")
    expect(shown_tasks_states).to be== ["executing", "failed", "pending"]

    find("select#tasks_select_condition").select("With failed trials")
    click_on("Filter")
    expect(shown_tasks_states).to be== ["failed"]

  end

  scenario "Filter tasks from execution show action by name", 
    browser: :firefox  do

    sign_in_as 'normin'
    visit workspace_execution_path(Execution.first)

    find("select#tasks_select_condition").select("All")
    click_on("Filter")

    expect(all(".task").count).to be>= 10

    find("input#name_substring_term").set("port OR attached")
    click_on("Filter")

    expect(all(".task").count).to be== 2
    expect(page).to have_content "port"
    expect(page).to have_content "attached"


  end

end


