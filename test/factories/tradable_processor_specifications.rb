FactoryGirl.define do
  factory :tradable_processor_specification do
    event_generation_profile nil
    processor_id 1
    processor_name "MyString"
    period_type 1
  end
end
