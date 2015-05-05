# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :definition do
    name { Faker::Name.last_name }
    job_specification { JobSpecification.first }
  end
end
