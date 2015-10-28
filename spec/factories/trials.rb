FactoryGirl.define do

  factory :executing_trial, class: 'Trial' do
    state 'executing'
  end

  factory :passed_trial, class: 'Trial' do
    state 'passed'
  end

  factory :pending_trial, class: 'Trial' do
    state 'pending'
  end

  factory :failed_trial, class: 'Trial' do
    state 'failed'

    after(:create) do |trial|
      FactoryGirl.create :trial_issue,
        type: 'error', trial: trial
    end

  end

  factory :trial_issue do
    title { Faker::Lorem.words(3).join(' ') }
    description { Faker::Lorem.paragraph }
    type { %w(error warning).sample }
  end

end
