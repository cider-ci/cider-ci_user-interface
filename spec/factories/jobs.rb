require 'digest/sha1'

FactoryBot.define do

  factory :job, aliases: [:executing_job] do
    state {'executing'}
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name { Faker::App.name }

    after(:create) do |job|
      FactoryBot.create :passed_task,
        job_id: job.id
      FactoryBot.create :executing_task,
        job_id: job.id
      FactoryBot.create :pending_task,
        job_id: job.id
    end
  end

  factory :pending_job, class: 'Job' do
    state {'pending'}
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name { Faker::App.name }

    after(:create) do |job|
      FactoryBot.create :pending_task,
        job_id: job.id
    end
  end

  factory :failed_job, class: 'Job' do
     state {'failed'}
     tree_id { Digest::SHA1.hexdigest rand.to_s }
     name { Faker::App.name }

     after(:create) do |job|
       FactoryBot.create :failed_task,
         job_id: job.id
       FactoryBot.create :passed_task,
         job_id: job.id
       FactoryBot.create :executing_task,
         job_id: job.id
       FactoryBot.create :pending_task,
         job_id: job.id
     end
  end

  factory :passed_job, class: 'Job' do
    state {'passed'}
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name { Faker::App.name }
    after(:create) do |job|
      FactoryBot.create :passed_task,
        job_id: job.id
      FactoryBot.create :passed_task,
        job_id: job.id
    end
  end

  factory :job_with_result, class: 'Job' do
    state {'passed'}
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name { Faker::App.name }
    result { { value: 42, summary: '42 OK' } }
    after(:create) do |job|
      task = FactoryBot.create :passed_task,
        job_id: job.id,
        result: { value: 42, summary: '42 OK' }
      task.trials.first.update! result: { value: 42, summary: '42 OK' }
    end
  end

  factory :job_with_issue, class: 'Job' do
    state {'failed'}
    tree_id { Digest::SHA1.hexdigest rand.to_s }
    name { Faker::App.name }

    after(:create) do |job|
      FactoryBot.create :job_issue,
        type: 'error', job: job
      FactoryBot.create :failed_task, job: job
    end
  end

  factory :job_issue do
    title { Faker::Lorem.words(3).join(' ') }
    description { Faker::Lorem.paragraph }
    type { %w(error warning).sample }
  end
end
