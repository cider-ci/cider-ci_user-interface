ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
require "spec_helper"
require "rspec/rails"
require "capybara/poltergeist"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

def truncate_tables
  PgTasks.truncate_tables
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.infer_base_class_for_anonymous_controllers = true
  config.order = "random"

  Capybara.register_driver :selenium_chrome do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome)
  end

  Capybara.register_driver :poltergeist_debug do |app|
    Capybara::Poltergeist::Driver.new(app, inspector: true)
  end

  Capybara.current_driver = :selenium

  if ENV["FIREFOX_ESR_PATH"].present?
    Selenium::WebDriver::Firefox.path = ENV["FIREFOX_ESR_PATH"]
  end

  def set_browser(example)
    Capybara.current_driver = case example.metadata[:browser]
      when :chrome
        :selenium_chrome
      when :headless, :jsbrowser
        :poltergeist
      when :rack_test
        :rack_test
      when :firefox
        :selenium
      else
        :selenium
      end
  end

  config.before(:each) do |example|
    truncate_tables
    User.find_or_create_by(login: "adam", is_admin: true).update!(
      first_name: "Adam", last_name: "Admin", password: "password",
    )
    User.find_or_create_by(login: "normin").update!(
      first_name: "Normin", last_name: "Normalo", password: "password",
    )
    set_browser(example)
  end

  config.after(:each) do |example|
    unless example.exception.nil?
      take_screenshot
    end
  end

  def take_screenshot
    @screenshot_dir ||= Rails.root.join("tmp", "capybara")
    begin
      Dir.mkdir @screenshot_dir
    rescue
      nil
    end
    path = @screenshot_dir.join("screenshot_#{Time.zone.now.iso8601.tr(":", "-")}.png")
    case Capybara.current_driver
    when :selenium, :selenium_chrome
      begin
        page.driver.browser.save_screenshot(path)
      rescue
        nil
      end
    when :poltergeist
      begin
        page.driver.render(path, full: true)
      rescue
        nil
      end
    else
      Rails.logger.warn "Taking screenshots is not
        implemented for #{Capybara.current_driver}.".squish
    end
  end
end

require "spec_helper_feature_shared"
