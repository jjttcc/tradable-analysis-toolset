# Settings for event generation for the associated tradable processors
# (that is, "TradableProcessorSpecification"s)
# Note: 'end_date' and 'analysis_period_length_seconds' are used to
# determine the start and end dates for analysis.
#!!!!!TO-DO: Determine and implement the logic for "now" (e.g., end_date =
#!!!!!null => "now")
class EventGenerationProfile < ApplicationRecord
  include Contracts::DSL, PeriodTypeConstants

  belongs_to :analysis_profile
  has_many   :tradable_processor_specifications, dependent: :destroy
  validates  :analysis_period_length_seconds, presence: true

  public

  attr_accessor :last_analysis_results

  public

  # The start date for the scheduled analysis
  pre :valid_analysis_period do analysis_period_length_seconds >= 0 end
  post :start_less_or_equal_end do |result| ! result.nil? &&
    (end_date.nil? || result <= end_date) end
  post :vr5 do |result| implies(end_date != nil,
                                Proc.new {result <= end_date}) end
  def start_date
    ending_date = end_date
    if ending_date.nil? then
      ending_date = DateTime.now
    end
    days = analysis_period_length_seconds / DAILY_ID
    result = ending_date - days.days
    result
  end

end
