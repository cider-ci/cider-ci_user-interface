require 'spec_helper'

def clean_db
  ActiveRecord::Base.connection.tap do |connection|
    connection.tables.reject { |tn| tn in ['schema_migrations', 'ar_internal_metadata']
    }.join(', ').tap do |tables|
      connection.execute " TRUNCATE TABLE #{tables} CASCADE; "
    end
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    clean_db
  end

  config.after(:all) do
    clean_db
  end

  config.after(:suite) do
    clean_db
  end
end
