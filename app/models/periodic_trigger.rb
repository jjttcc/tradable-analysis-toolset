class PeriodicTrigger < ApplicationRecord
  has_many :analysis_schedules, as: :triggered_by #!!!!{event-gen}
end
