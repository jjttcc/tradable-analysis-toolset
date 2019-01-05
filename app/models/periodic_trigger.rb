=begin
interval_seconds: integer
time_window_start: time
time_window_end: time
schedule_type: integer
=end

# Triggers that are activated based on a definite period of time - for
# example, hourly, or every minute
class PeriodicTrigger < ApplicationRecord
  include Contracts::DSL

  has_many :analysis_schedules, as: :trigger
end
