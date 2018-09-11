# Settings for event generation for the associated tradable processors
# (i.e., "TradableProcessorSpecification"s)
# Note: 'end_date' and 'analysis_period_length_seconds' are used to
# determine the start and end dates for analysis.
#!!!!!TO-DO: Determine and implement the logic for "now" (e.g., end_date =
#!!!!!null => "now")
class EventGenerationProfile < ApplicationRecord
  belongs_to :analysis_profile
  has_many   :tradable_processor_specifications #!!!!{event-gen}
end
