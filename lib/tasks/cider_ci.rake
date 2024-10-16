namespace :cider_ci do
  task import_data: :environment do
    require "cider_ci/data"
    CiderCI::Data.import(ENV["FILE"].presence || raise("No FILE given."))
  end
end
