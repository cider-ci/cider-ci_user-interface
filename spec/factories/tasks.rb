FactoryBot.define do
  factory :executing_task, class: "Task" do
    state { "executing" }
    name { Faker::Lorem.sentence }
    after(:create) do |task|
      FactoryBot.create :executing_trial,
        task_id: task
    end
  end

  factory :failed_task, class: "Task" do
    state { "failed" }
    name { Faker::Lorem.sentence }
    after(:create) do |task|
      FactoryBot.create :failed_trial,
        task_id: task
    end
  end

  factory :passed_task, class: "Task" do
    state { "passed" }
    name { Faker::Lorem.sentence }
    after(:create) do |task|
      FactoryBot.create :passed_trial,
        task_id: task
    end
  end

  factory :pending_task, class: "Task" do
    state { "pending" }
    name { Faker::Lorem.sentence }
    after(:create) do |task|
      FactoryBot.create :pending_trial,
        task_id: task
    end
  end
end
