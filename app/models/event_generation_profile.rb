=begin
  # The date-time at which the analysis is to end
  end_date:                       datetime

  # Used to determine 'start_date'
  analysis_period_length_seconds: integer
=end

# Settings for analysis runs - with configured "start" and "end"
# date/times -, using the associated tradable processors (i.e.,
# "TradableProcessorSpecification"s)
# Note: 'end_date' and 'analysis_period_length_seconds' are used to
# determine the start and end dates for analysis.
#!!!!!TO-DO: Determine and implement the logic for "now" (e.g., end_date =
#!!!!!null => "now")  [!!!!Put this note somewhere - e.g., tat-todo!!!!]
class EventGenerationProfile < ApplicationRecord
  include Contracts::DSL, PeriodTypeConstants

  public

  belongs_to :analysis_profile
  has_many   :tradable_processor_specifications, dependent: :destroy
  validates  :analysis_period_length_seconds, presence: true

  public

  # The last AnalysisRun resulting from analysis based on self's specs
  #!!!![might go away:]!!!!!
  attr_accessor :last_analysis_run

  public

  ###  Access

  # The start date for the scheduled analysis
  pre :valid_analysis_period do analysis_period_length_seconds >= 0 end
  post :start_less_or_equal_end do |result| ! result.nil? &&
    (end_date.nil? || result <= end_date) end
  post :vr5 do |result| implies(end_date != nil,
                                Proc.new {result <= end_date}) end
  def start_date
    ending_date = end_date
    if ending_date.nil? then
      ending_date = DateTime.current
#!!!!      ending_date = DateTime.now
    end
    days = analysis_period_length_seconds / DAILY_ID
    result = ending_date - days.days
    result
  end

  def client_name
    analysis_profile.client_name
  end

  def user
    analysis_profile.user
  end

end
