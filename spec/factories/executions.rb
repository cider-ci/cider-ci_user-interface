require 'digest/sha1'

FactoryGirl.define do

  factory :execution do
    state "executing"
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name {Faker::App.name}
    
    after(:create) do |execution|
      FactoryGirl.create :passed_task, 
        execution_id: execution.id
      FactoryGirl.create :executing_task, 
        execution_id: execution.id
      FactoryGirl.create :pending_task, 
        execution_id: execution.id
    end
  end


  factory :failed_execution, class: "Execution" do
    state "failed"
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name {Faker::App.name}
    
    after(:create) do |execution|
      FactoryGirl.create :failed_task, 
        execution_id: execution.id
    end
  end

end
