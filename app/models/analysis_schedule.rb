class AnalysisSchedule < ApplicationRecord
  belongs_to :triggered_by, polymorphic: true
  belongs_to :user
  has_many   :analysis_profiles, as: :analysis_client #!!!!{event-gen}
end
