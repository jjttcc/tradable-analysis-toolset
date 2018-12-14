# Events resulting from an analysis run a specific
# TradableProcessorSpecification
class AnalysisEvent < ApplicationRecord
  include TradableEventInterface, Contracts::DSL

  public

  belongs_to      :tradable_event_set

  alias_attribute :datetime, :date_time
  alias_attribute :event_type_id, :signal_type

  attr_accessor   :event_id, :analyzer

  def event_id=(id)
    @event_id = id.to_i
  end

end
