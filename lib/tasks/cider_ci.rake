namespace :cider_ci do
  task dump_core: :environment do
    require 'cider_ci/data'
    file_name = (ENV['FILE'].present? && ENV['FILE']) || "tmp/core_data.yml"
    data=CiderCI::Data.dump_core 
    File.open(file_name ,'w'){|f| f.write data.to_yaml}
    puts "core data has been dumped into #{file_name}"
  end
  task import_core: :environment do
    require 'cider_ci/data'
    file_name = (ENV['FILE'].present? && ENV['FILE']) || "tmp/core_data.yml"
    data= YAML.load_file file_name
    require 'cider_ci/data'
    CiderCI::Data.import_core data
  end
end
