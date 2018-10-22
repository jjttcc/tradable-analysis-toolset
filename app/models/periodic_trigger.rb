class PeriodicTrigger < ApplicationRecord
  has_many :analysis_schedules, as: :trigger #!!!!{event-gen}
end
