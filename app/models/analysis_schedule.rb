class AnalysisSchedule < ApplicationRecord
  belongs_to :trigger, polymorphic: true
  belongs_to :user
  has_many   :analysis_profiles, as: :analysis_client
end
