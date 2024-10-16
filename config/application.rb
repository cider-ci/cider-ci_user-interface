require_relative "boot"

require "rails/all"

require "active_support/core_ext/numeric/bytes"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

######################################################################

Settings = {}.with_indifferent_access
["../config/config_default.yml",
  "config/settings.yml",
  "../config/config.yml",
  "../config/releases.yml",
  "config/settings.local.yml",
  "/cider-ci/data/config/config.yml"].each do |config_file|
  if File.exist? config_file
    config = YAML.load_file(config_file).to_h.with_indifferent_access
    Settings.deep_merge! config
  end
end

#####################################################################

module CiderCI
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    config.active_record.schema_format = :sql
    config.active_record.timestamped_migrations = false

    config.paths["db/migrate"] <<
      Rails.root.join("database", "db", "migrate")

    config.paths["config/initializers"] <<
      Rails.root.join("database", "initializers")

    config.eager_load_paths += [
      Rails.root.join("lib"),
      Rails.root.join("database", "lib"),
      Rails.root.join("database", "app", "models", "concerns"),
      Rails.root.join("database", "app", "controllers"),
      Rails.root.join("database", "app", "controllers", "concerns"),
      Rails.root.join("database", "app", "models"),
      Rails.root.join("database", "app", "lib"),
      Rails.root.join("database", "app", "queries")
    ]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.autoloader = :classic
  end
end
