require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Managing Executors as Admin ", browser: :firefox  do

  scenario "Creating a new executor"  do
    Executor.destroy_all
    sign_in_as 'adam'
    click_on "Administration" 
    click_on "Executors" 
    click_on "Add a new executor" 

    find("input#executor_name").set "Executor1"
    find("input#executor_traits").set "trait1, trait2"
    find("input#executor_host").set "executor1.example.com"
    click_on "Create"
    expect(page).to have_content "has been created"
    expect(Executor.first.traits.sort).to be== %w(trait1 trait2)
    expect(Executor.first.name).to be== "Executor1"
    expect(Executor.first.host).to be== "executor1.example.com"
  end

end 





