=begin
status: integer (NOT NULL)
error_message: varchar
contact_identifier: varchar (NOT NULL)
synopsis: varchar
medium_type: integer (NOT NULL)
=end

class Notification < ApplicationRecord
  include Contracts::DSL

  public

  belongs_to :notification_source, polymorphic: true
  belongs_to :user

  enum status: {
    initial:   1,   # "send" attempt not yet made
    sending:   2,   # in the process of being sent
    sent:      3,   # sent, but delivery not yet (or cannot be) confirmed
    delivered: 4,   # sent and delivered confirmed
    failed:    5,   # "send" attempted, but a failure result was detected
    again:     6,   # temporary failure of "send" - retry needed
  }

  # (Copied from NotificationAddress)
  enum medium_type: {
    email:      1,
    text:       2,
    telephone:  3,
    #...
  }

end
