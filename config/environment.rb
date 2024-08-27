# Load the Rails application.
require_relative 'application'

# Set Haml output to ugly everywhere
Haml::Template.options[:ugly] = true

# Initialize the rails application.
CiderCI::Application.initialize!
