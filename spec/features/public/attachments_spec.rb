require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Attachments' do

  scenario 'redirect to existing tree attachment, view public and private',
           browser: :firefox do

    Repository.first.update_attributes! name: 'TestRepo'
    Repository.all.each { |r| r.update_attributes! public_view_permission: true }
    attachment = TreeAttachment.first

    visit "/public/attachments/testrepo/master/tests/#{
      attachment.path.split('/').drop(2).join('/')}"
    expect(page).to have_content 'Attachment /log/hello.log'
    expect(page.text.downcase).to have_content 'content-type:'

    Repository.all.each { |r| r.update_attributes! public_view_permission: false }
    visit(current_path)
    expect(page).to have_content '401 Unauthorized'

  end

  scenario 'redirect to not existing tree attachment',
           browser: :firefox do
    Repository.first.update_attributes! name: 'TestRepo'

    visit '/public/attachments/testrepo/master/tests/blah.txt'
    expect(page).to have_content '404 Not found'
    expect(page).to have_content 'try again later'

    visit '/public/attachments/testrepo/nobranch/tests/blah.txt'
    expect(page).to have_content '404 Not found'
    expect(page).to have_content 'try again later'

    visit workspace_attachment_path('tree_attachment', 'noway.txt')
    expect(page).to have_content '404 Not found'
    expect(page).to have_content 'try again later'

  end

end
