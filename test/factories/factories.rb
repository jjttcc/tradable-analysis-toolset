class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
end

FactoryGirl.define do
  factory :user do
    email_addr             "memy@example.com"
    password               "oboefoobar"
    password_confirmation  "oboefoobar"
  end
end

FactoryGirl.define do
  sequence :email do |n|
    "user-#{n}@users.org"
  end
end

FactoryGirl.define do
  factory :person do
    start_date DateTime.yesterday
    end_date DateTime.current
#!!!!    end_date DateTime.now
    period_type_id PeriodTypeConstants::DAILY_ID
    category PeriodTypeSpec::SHORT_TERM
    association :user
  end
end

FactoryGirl.define do
  factory :period_type_spec do
    period_type_id PeriodTypeConstants::DAILY_ID
    start_date DateTime.current
#!!!!    start_date DateTime.now
    category PeriodTypeSpec::SHORT_TERM
    association :user
  end
end
