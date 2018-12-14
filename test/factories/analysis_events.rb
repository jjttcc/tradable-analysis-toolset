FactoryGirl.define do
  factory :analysis_event do
    tradable_event_set nil
    event_type_id 1
    date_time "2018-12-09 19:33:54"
    signal_type "MyString"
  end
end
