# Specifications for an analysis run for a specific TradableProcessor
# Note: 'period_type' is the number of seconds of the associated period type -
# e.g., 86_400 for a daily period type.  (See PeriodTypeConstants.)
class TradableProcessorSpecification < ApplicationRecord
  belongs_to :event_generation_profile
  has_many   :tradable_processor_parameters, dependent: :destroy

  public

  # 'event_id' of the associated TradableProcessor
  def event_id; processor_id end

  # 'name' of the associated TradableProcessor
  def name; TradableAnalyzer.find_by_event_id(event_id).name end

  # name for 'period_type'
  def period_type_name
    PeriodTypeConstants::name_for[period_type]
  end

end
