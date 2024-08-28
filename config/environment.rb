# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
CiderCI::Application.initialize!

# Set Haml output to ugly everywhere
Haml::Template.options[:ugly] = true
