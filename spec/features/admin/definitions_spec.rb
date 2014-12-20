require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature "Managing execution definitions as admin ", browser: :firefox  do

  scenario "Browsing to the execution definition page" do
    sign_in_as 'adam'
    click_on "Administration" 
    click_on "definitions" 
    expect(current_path).to be== admin_definitions_path
  end

  scenario "Create a definition, edit and destroy it" do
    Definition.destroy_all
    Execution.destroy_all
    Specification.destroy_all
    Definition.destroy_all
    sign_in_as 'adam'
    visit admin_definitions_path
    click_on "Create a definition"
    find("input#definition_name").set "TestDefinition"
    find("textarea#definition_description").set "Blah blah blah."
    test_spec= YAML.load_file Rails.root.join "spec", "data", "execution-spec-v2_show-info-example.yml"
    find("textarea#specification_data").set test_spec.to_yaml
    click_on("Create")
    expect(page).to have_content "been created"
    expect(page).to have_content "Blah blah blah."
    expect(Specification.first.data).to be== test_spec

    click_on("Edit")
    find("textarea#definition_description").set "Bluh bluh bluh."
    click_on("Save")
    expect(page).to have_content "been updated"
    expect(page).to have_content "Bluh bluh bluh."


    click_on("Delete")
    expect(page).to have_content "been deleted"
    expect(page).not_to have_content "Bluh bluh bluh."

  end


  scenario "Create a definition with invalid syntax" do
    sign_in_as 'adam'
    visit admin_definitions_path
    click_on "Create a definition"
    find("input#definition_name").set "TestDefinition"
    find("textarea#definition_description").set "Blah blah blah."
    find("textarea#specification_data").set "x: 5\n y: 7"
    click_on("Create")
    expect(page).to have_content "Psych::SyntaxError"
  end


end
