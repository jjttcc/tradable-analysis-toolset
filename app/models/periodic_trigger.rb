# Triggers that are activated based on a definite period of time - for
# example, hourly, or every minute
class PeriodicTrigger < ApplicationRecord
  include Contracts::DSL

  has_many :analysis_schedules, as: :trigger
end
