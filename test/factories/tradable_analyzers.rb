FactoryGirl.define do
  factory :tradable_analyzer do
    name "MyText"
    event_id 1
    is_intraday false
    mas_session nil
  end
end
