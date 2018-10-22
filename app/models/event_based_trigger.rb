class EventBasedTrigger < ApplicationRecord
    enum triggered_event_type: {
      user_triggered:         1,
      EOD_US_stocks:          2,
      # etc...
    }

  has_many :analysis_schedules, as: :trigger
end
