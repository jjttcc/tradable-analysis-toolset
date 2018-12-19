class Notification < ApplicationRecord
  include Contracts::DSL

  public

  belongs_to :notification_source, polymorphic: true
  belongs_to :user
  # (Note self-reference - i.e., composite pattern)
  has_many   :notifications, as: :notification_source, dependent: :destroy

  enum status: {
    initial:   1,   # i.e., not yet sent
    sent:      2,   # i.e., delivery not yet (or cannot be) confirmed
    delivered: 4,
    failed:    3,   # send attempted, but a failure result was detected
  }

end
