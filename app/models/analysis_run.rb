=begin
status: integer
start_date: datetime
end_date: datetime
analysis_profile_name: varchar
analysis_profile_client: varchar
run_start_time: datetime
=end

# A permanent record of the results of a MAS analysis run using the
# values (start_date, end_date, set-of: {event_id, trad_pertype}) from the
# associated EventGenerationProfile for which the analysis was performed
class AnalysisRun < ApplicationRecord
  include Contracts::DSL

  public

  belongs_to :user
  has_many   :tradable_processor_runs, dependent: :destroy

  # The time at which the analysis run was completed
  alias_attribute :completion_time, :updated_at

  enum status: {
    completed:  1,
    running:    2,
    failed:     3,
    notified:   4,
  }

  public

  post :exists do |result| ! result.nil? end
  def all_events
    result = []
    tradable_processor_runs.each do |r|
      result.concat(r.all_events)
    end
    result
  end

end
