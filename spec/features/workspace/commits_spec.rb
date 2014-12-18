require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Browse commits", browser: :firefox  do

  scenario "Top link to commits" do
   sign_in_as 'normin'
   visit "/public"
   click_on "Commits"
   expect(current_path).to be== workspace_commits_path
  end

  scenario "Filtering" do 
    sign_in_as 'normin'
    visit workspace_commits_path
    find("select#commited_within_last_days").select("10 years")
    click_on("Filter")
    expect(all(".commit").count).to be>= 5
    find("input#repository_names").set("ci")
    find(".ui-autocomplete").find("a",text: "Cider").click
    find("input#branch_names").set("ma")
    find(".ui-autocomplete").find("a",text: "master").click
    find("input#commit_text").set("Initial")
    click_on("Filter")
    expect(all(".commit").count).to be== 1
  end


end



