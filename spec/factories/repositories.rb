# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :repository do
    name { Faker::Lorem.word }
    origin_uri { Faker::Internet.url }
  end
end
