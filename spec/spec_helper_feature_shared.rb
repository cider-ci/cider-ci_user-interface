require "addressable/uri"

# A few global functions shared between all rspec feature tests.
#
# * Keep this file lexically sorted.
#
# * Keep this file small and simple.
#
# * Only simple functions shall be included.
#
# * Only general functions shall be included.
#
# Favor clearness, and simplicity instead of dryness!
#

def accept_alert_dialog
  unless Capybara.current_driver == :poltergeist
    page.driver.browser.switch_to.alert.accept
  end
end

def assert_alert_dialog
  expect(page.driver.browser.switch_to.alert.text).not_to be_blank
end

def assert_change_of_current_path
  expect(@current_path).not_to eq(page.current_path)
end

def assert_error_alert(message = nil)
  find(".ui-alert.error", text: message)
end

def assert_exact_url_path(path)
  expect(current_path).to eq path
end

def assert_modal_not_visible
  expect(page).not_to have_selector ".modal-backdrop"
end

def assert_modal_visible(title = nil)
  within(".modal .ui-modal-head") do
    expect(find("*", text: title)).to be if title
  end
end

def assert_partial_url_path(path)
  expect(current_path).to match path
end

def assert_selected_option(select_css_matcher, option_text)
  expect(find("#{select_css_matcher} option", text: option_text)).to be_selected
end

def assert_success_message
  expect(page).to have_selector(".alert-success,.ui-alert.success")
end

def change_value_of_some_input_field
  expect(page).to have_selector "input[type=text]"
  all("input[type=text]").sample.set "123"
end

def click_link_from_menu(text, parent_text = nil)
  if parent_text
    find(".navbar-nav > li > a", text: parent_text).click
  end
  within find(".navbar-nav", match: :first) do
    find("a", text: text).click
  end
end

def click_on_button(text)
  find(".button[title='#{text}']").click
end

def click_on_text(text)
  find("a, button", text: text, match: :first).click
end

def click_primary_action_of_modal
  find(".ui-modal .primary-button").click
end

def find_input_with_name(name)
  first("textarea,input[name='#{name}']")
end

# firefox only! - needs browser driver to support it
def move_mouse_over(element)
  page.driver.browser.action.move_to(element.native).perform
  # it's gonna be easier in capybara < 2.1
  # element.hover
end

def sign_in_as(login, password = "password")
  visit "/public" unless current_path
  find("input[type='text']").set login
  find("input[type='password']").set password
  find("button[type='submit']").click
end

def sign_out
  find("#user-actions").click
  click_on "Sign out"
end

def submit_form(id = nil)
  el = (id ? first("form##{id}") : page)
  el.first("[type='submit']").click
end

def current_fragment
  Addressable::URI.parse(current_url).fragment
end

def visit(_most_recent_job)
  visit(Execufion.reorder("created_at DESC").first)
end
