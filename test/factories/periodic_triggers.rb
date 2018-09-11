FactoryGirl.define do
  factory :periodic_trigger do
    interval_seconds 1
    time_window_start "2018-09-03 05:11:35"
    time_window_end "2018-09-03 05:11:35"
    daily_schedule 1
  end
end
