source 'https://rubygems.org'

####################################################################
# required for PRODUCTION
####################################################################

# RAILS
gem 'rails', '~> 4.2'

# DATABASE
gem 'activerecord-jdbcpostgresql-adapter',  platform: :jruby
gem 'jdbc-postgres', platform: :jruby
gem 'pg', platform: 'mri'
gem 'pg_tasks', '>= 1.3.0', '< 2.0.0'
gem 'drtom-textacular', '= 4.0.0.alpha.20160302'


# FRONTEND
gem 'bootstrap-sass'
gem 'coffee-rails'
gem 'font-awesome-sass', '= 4.4.0'
gem 'haml-contrib'
gem 'haml-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-ui-sass-rails'
gem 'kramdown'
gem 'sass'
gem 'sass-rails'


# The rest
gem 'bcrypt-ruby'
gem 'bootswatch-rails'
gem 'bunny', '>= 1.3'
gem 'chronic_duration'
gem 'cider_ci-open_session', '>= 1.0.0', '< 2.0.0'
gem 'configuration_management_backdoor', '>= 3.0.0', '< 4.0.0' #path: '/Users/thomas/Programming/ROR/ConfigurationManagementBackdoor'
gem 'faraday'
gem 'inshape', '>= 1.0.1', '< 2.0'
gem 'kaminari'
gem 'newrelic_rpm'
gem 'nilify_blanks'
gem 'psych', platform: :mri # (j)psych is yet directly included in jruby
gem 'puma'
gem 'rack-mini-profiler'
gem 'rest-client'
gem 'therubyrhino', platform: :jruby
gem 'uglifier'
gem 'uuidtools'

####################################################################
# TEST or DEVELOPMENT only
#####################################################################

gem 'addressable', group: [:test]
gem 'capybara', group: [:test]
gem 'cider_ci-support', '~> 1.2.0', group: [:development, :test]
gem 'factory_girl', group: [:development, :test]
gem 'factory_girl_rails', group: [:development, :test]
gem 'faker', group: [:development, :test]
gem 'poltergeist', group: [:test]
gem 'pry', group: [:development, :test]
gem 'rspec-rails', group: [:development, :test]
gem 'rubocop', group: [:development, :test], require: false
gem 'sdoc', group: [:doc], require: false
gem 'selenium-webdriver', group: [:test]
gem 'timecop', group: [:development, :test]

# TODO, find unused views and partials after we have some tests
# https://github.com/vinibaggio/discover-unused-partials

# gem 'bootswatch-sprockets', "= 0.2.0.pre.beta.10"
# gem 'sass-rails',
#   git: 'https://github.com/DrTom/sass-rails.git',
#   ref: '849e40e69b6017486b757811b807b3810705682a'
