# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :definition do
    name { Faker::Name.last_name }
    job_specification { JobSpecification.first }
  end
end
