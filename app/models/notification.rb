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
#!!!  # (Note self-reference - i.e., composite pattern!!!![likely will go away]!!!!)
#!!!  has_many   :notifications, as: :notification_source, dependent: :destroy

  enum status: {
    initial:   1,   # i.e., "send" attempt not yet made
    sent:      2,   # i.e., delivery not yet (or cannot be) confirmed
    delivered: 4,
    failed:    3,   # send attempted, but a failure result was detected
  }

  # (Copied from NotificationAddress)
  enum medium_type: {
    email:      1,
    text:       2,
    telephone:  3,
    #...
  }

end
