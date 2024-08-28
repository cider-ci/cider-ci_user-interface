require_relative 'boot'

require 'active_support/core_ext/numeric/bytes'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

######################################################################

Settings = {}.with_indifferent_access
[ '../config/config_default.yml',
  'config/settings.yml',
  '../config/config.yml',
  '../config/releases.yml',
  'config/settings.local.yml',
  '/cider-ci/data/config/config.yml'
].each do |config_file|
  if File.exist? config_file
    config = YAML.load_file(config_file).to_h.with_indifferent_access
    Settings.deep_merge! config
  end
end


#####################################################################


module CiderCI
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
