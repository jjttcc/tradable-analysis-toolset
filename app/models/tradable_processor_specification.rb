# !!!!!TBD: class description!!!!!
# Note: 'period_type' is the number of seconds of the associated period type -
# e.g., 86_400 for a daily period type.  (See PeriodTypeConstants.)
class TradableProcessorSpecification < ApplicationRecord
  belongs_to :event_generation_profile
  has_many   :tradable_processor_parameters #!!!!{event-gen}
end
