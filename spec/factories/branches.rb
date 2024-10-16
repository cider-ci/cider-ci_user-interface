# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :branch do
    name { Faker::Lorem.word }
  end
end
