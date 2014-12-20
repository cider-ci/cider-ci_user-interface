require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Managing repositories as admin ", browser: :firefox  do

  scenario "Browsing to the repository page" do
    sign_in_as 'adam'
    click_on "Administration" 
    click_on "Repositories" 
    expect(current_path).to be== admin_repositories_path
  end

  scenario "Create a repository, editing and deleting it" do
    Repository.destroy_all
    sign_in_as 'adam'
    visit admin_repositories_path
    click_on 'Add a new repository'
    find("input#repository_name").set "TestRepo"
    find("input#repository_origin_uri").set \
      "https://github.com/cider-ci/cider-ci_demo-project-bash.git"
    click_on 'Create'
    expect(page).to have_content 'created'
    click_on 'TestRepo'
    click_on 'Edit'
    find("input#repository_name").set "UpdatedName"
    click_on 'Save'
    expect(page).to have_content 'updated'
    expect(page).to have_content  "UpdatedName"
    click_on 'Delete'
    expect(page).to have_content 'deleted'
    expect(Repository.count).to be== 0
  end

end

