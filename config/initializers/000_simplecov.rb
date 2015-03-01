# it is important that this file is loaded prior to any
# code that is to be checked for coverage
if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  SimpleCov.start 'rails' do
    # add_filter "/spec/"
    add_filter 'app/messaging/messaging.rb'
    merge_timeout 48 * 3600
    use_merging true
  end
  puts 'required simplecov'
end
