=begin
symbol: varchar NOT NULL
=end

# A set of "AnalysisEvent"s (or tradable events) resulting from an analysis
# run of a specific MAS market analyzer (AKA tradable processor or
# event generator) for a specified time period and a specified tradable
# (e.g., stock) symbol, based on settings specified by a
# TradableProcessorSpecification
class TradableEventSet < ApplicationRecord
  public

  belongs_to :tradable_processor_run
  has_many   :analysis_events, dependent: :destroy

end
