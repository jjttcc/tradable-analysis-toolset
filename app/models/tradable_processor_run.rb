=begin
analysis_run_id integer NOT NULL
processor_id integer NOT NULL
period_type integer NOT NULL
=end

# The results of an AnalysisRun using a specific
# TradableProcessorSpecification (which is associated with a
# TradableAnalyzer [e.g., "MACD Crossover (Buy)"]) for an analysis request
# (i.e., mas_client.request_analysis), consisting of one or more
# TradableEventSets (one for each symbol used in the request), each of
# which holds the AnalysisEvents for its symbol for that run.
class TradableProcessorRun < ApplicationRecord
  include Contracts::DSL

  public

  belongs_to :analysis_run
  has_many   :tradable_event_sets, dependent: :destroy
  has_many   :tradable_processor_parameter_settings, dependent: :destroy

  public

  # The name of the associated TradableProcessorSpecification/TradableAnalyzer
  post :exists do |result| result != nil && ! result.empty? end
  def processor_name
    result = ""
    p = TradableProcessorSpecification.find_by_processor_id(processor_id)
    result = p.name
  end

  def all_events
    result = []
    tradable_event_sets.each do |s|
      result.concat(s.analysis_events)
    end
    result
  end

  # All events in the element of tradable_event_sets whose 'symbol' matches
  # 's'
  def events_for_symbol(s)
    events_by_symbol[s]
  end

  private

  def events_by_symbol
    if @event_symbol_map.nil? then
      @event_symbol_map = {}
      tradable_event_sets.each do |s|
        @event_symbol_map[s.symbol] = s.analysis_events
      end
    end
    @event_symbol_map
  end

end
