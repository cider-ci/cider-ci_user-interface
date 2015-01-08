require 'digest/sha1'

FactoryGirl.define do

  factory :execution, aliases: [:executing_execution] do
    state 'executing'
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name { Faker::App.name }

    after(:create) do |execution|
      FactoryGirl.create :passed_task,
                         execution_id: execution.id
      FactoryGirl.create :executing_task,
                         execution_id: execution.id
      FactoryGirl.create :pending_task,
                         execution_id: execution.id
    end
  end

  factory :pending_execution, class: 'Execution' do
    state 'pending'
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name { Faker::App.name }

    after(:create) do |execution|
      FactoryGirl.create :pending_task,
                         execution_id: execution.id
    end
  end

  factory :failed_execution, class: 'Execution' do
     state 'failed'
     tree_id { Digest::SHA1.hexdigest rand.to_s }
     name { Faker::App.name }

     after(:create) do |execution|
       FactoryGirl.create :failed_task,
                          execution_id: execution.id
       FactoryGirl.create :passed_task,
                          execution_id: execution.id
       FactoryGirl.create :executing_task,
                          execution_id: execution.id
       FactoryGirl.create :pending_task,
                          execution_id: execution.id
     end
  end

  factory :passed_execution, class: 'Execution' do
    state 'passed'
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name { Faker::App.name }
    after(:create) do |execution|
      FactoryGirl.create :passed_task,
                         execution_id: execution.id
      FactoryGirl.create :passed_task,
                         execution_id: execution.id
    end
  end

  factory :execution_with_result, class: 'Execution' do
    state 'passed'
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name { Faker::App.name }
    result ({ value: 42, summary: '42 OK' })
    after(:create) do |execution|
      task = FactoryGirl.create :passed_task,
                                execution_id: execution.id,
                                result: { value: 42, summary: '42 OK' }
      task.trials.first.update_attributes! result: { value: 42, summary: '42 OK' }
    end
  end

  factory :execution_with_issue, class: 'Execution' do
    state 'failed'
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name { Faker::App.name }

    after(:create) do |execution|
      FactoryGirl.create :execution_issue,
                         type: 'error', execution: execution
    end
  end

  factory :execution_issue do
    description { Faker::Lorem.sentence }
    type { %w(error warning).sample }
  end
end
