require "factory_bot"
require "factory_bot_rails"

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # double includes with this ?
  #
  #  config.before(:suite) do
  #    FactoryBot.find_definitions
  #  end
end
