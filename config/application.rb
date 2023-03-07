require_relative 'boot'

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
  if File.exists? config_file
    config = YAML.load_file(config_file).to_h.with_indifferent_access
    Settings.deep_merge! config
  end
end


#####################################################################


module CiderCI

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2


    config.paths['db/migrate'] << \
      Rails.root.join('datalayer', 'db', 'migrate')

    config.paths['config/initializers'] <<  \
      Rails.root.join('datalayer', 'initializers')

    config.eager_load_paths += [
      Rails.root.join('lib'),
      Rails.root.join('datalayer', 'lib'),
    ]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    #
    config.active_record.timestamped_migrations = false

    config.action_controller.relative_url_root = '/cider-ci/ui'

    config.cache_store = :memory_store, {size: (Settings[:ui_cache_size_megabytes].presence || 128).megabytes}

  end
end
