Factory.define :user do |u|
  u.email_addr             "memy@example.com"
  u.password               "oboefoobar"
  u.password_confirmation  "oboefoobar"
end

Factory.sequence :email do |n|
  "user-#{n}@users.org"
end
