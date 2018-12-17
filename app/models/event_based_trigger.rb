# Triggers that are activated by an external event
class EventBasedTrigger < ApplicationRecord
#!!!  include Trigger, Contracts::DSL
  include Contracts::DSL

  has_many :analysis_schedules, as: :trigger

  private

  enum triggered_event_type: {
    user_triggered:         1,
    EOD_US_stocks:          2,
    # etc...
  }

end
