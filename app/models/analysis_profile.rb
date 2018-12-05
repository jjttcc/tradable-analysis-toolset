=begin
### attributes:

# The profile name
name

# Should analysis results for the run be saved to the database?
save_results
=end

# Profiles for analysis runs of one or more event_generation_profiles, each
# of which has a separate start and end date/time - can be scheduled for
# future analysis runs or run immediately
class AnalysisProfile < ApplicationRecord
  belongs_to :analysis_client, polymorphic: true
  has_many   :event_generation_profiles, dependent: :destroy

end
