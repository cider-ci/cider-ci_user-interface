FactoryGirl.define do

  factory :executing_trial, class: "Trial" do
    state "executing" 
  end

  factory :passed_trial, class: "Trial" do
    state "passed" 
  end

  factory :pending_trial, class: "Trial" do
    state "pending" 
  end

 factory :failed_trial, class: "Trial" do
    state "failed" 
  end

end

