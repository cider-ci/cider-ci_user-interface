# Load the rails application.
require File.expand_path('../application', __FILE__)

# Set Haml output to ugly everywhere
Haml::Template.options[:ugly] = true

# Initialize the rails application.
CiderCI::Application.initialize!
