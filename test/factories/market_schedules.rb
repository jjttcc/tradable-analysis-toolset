FactoryGirl.define do
  factory :market_schedule do
    market nil
    schedule_type 1
    date "2019-01-27"
    pre_market_start_time "2019-01-27 18:27:44"
    pre_market_end_time "2019-01-27 18:27:44"
    post_market_start_time "2019-01-27 18:27:44"
    post_market_end_time "2019-01-27 18:27:44"
    core_start_time "2019-01-27 18:27:44"
    core_end_time "2019-01-27 18:27:44"
  end
end
