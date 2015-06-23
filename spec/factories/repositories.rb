# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :repository do
    name { Faker::Lorem.word }
    git_url { Faker::Internet.url }
  end
end
