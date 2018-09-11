class AnalysisProfile < ApplicationRecord
  belongs_to :analysis_client, polymorphic: true
  has_many   :event_generation_profiles #!!!!{event-gen}
end
