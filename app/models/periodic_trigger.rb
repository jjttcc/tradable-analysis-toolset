=begin
interval_seconds: integer
time_window_start: time
time_window_end: time
schedule_type: integer
=end

# Triggers that are activated based on a definite period of time - for
# example, hourly, or every minute
class PeriodicTrigger < ApplicationRecord
  include Contracts::DSL, TriggerStatus

  has_many :analysis_schedules, as: :trigger

  private

  enum status: {
    available:   1,   # not activated or not yet invoked
    busy:        2,   # invoked - resulting schedules are being processed
    closed:      3,   # triggered-event was processed, ready for re-use
    not_in_use:  4,   # i.e., it should be ignored
    # etc...
  }

end
