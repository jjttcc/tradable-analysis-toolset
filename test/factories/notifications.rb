FactoryGirl.define do
  factory :notification do
    notification_source nil
    status 1
    error_message "MyString"
    contact_identifier "MyString"
    synopsis "MyString"
    medium_type 1
    user nil
  end
end
