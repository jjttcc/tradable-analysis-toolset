Factory.define :user do |u|
  u.email_addr             "memy@example.com"
  u.password               "oboefoobar"
  u.password_confirmation  "oboefoobar"
end

Factory.sequence :email do |n|
  "user-#{n}@users.org"
end

Factory.define :period_type_spec do |p|
  p.start_date DateTime.yesterday
  p.end_date DateTime.now
  p.period_type_id PeriodTypeConstants::DAILY_ID
  p.category PeriodTypeSpec::SHORT_TERM
  p.association :user
end
