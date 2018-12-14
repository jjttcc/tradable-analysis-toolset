#!!!!!!!!!!!![Remove this when finished with app/models/tradable_event.rb:]
require_relative '../../library/test/test_tradable_event'
#!!!!!!!!!!!!!!!

class TradableObjectFactory
  include TimePeriodTypeConstants

  # A new TradableAnalyzer with the specified name and id
  def new_analyzer(name:, id:, period_type:)
    result = TradableAnalyzer.find_by_event_id(id)
    if result == nil then
      TradableAnalyzer.create!(name: name, event_id: id,
                               is_intraday: is_intraday(period_type))
    end
    result
  end

  def new_event(date:, time:, id:, type_id:, analyzers:)
    datetime = DateTime.new(date[0..3].to_i, date[4..5].to_i, date[6..7].to_i,
                            time[0..1].to_i, time[2..3].to_i, time[4..5].to_i)
    selected_ans = analyzers.select {|a| a.event_id.to_s == id }
    if selected_ans.length == 0 then
      raise "new_event: id arg, #{id} " +
        "does not identify any known analyzer."
    else
      analyzer = selected_ans[0]
    end
    result = AnalysisEvent.new(date_time: datetime, signal_type: type_id)
    result.analyzer = analyzer
    result.event_id = id
    result
  end

  def obsolete___new_event(date:, time:, id:, type_id:, analyzers:)
    datetime = DateTime.new(date[0..3].to_i, date[4..5].to_i, date[6..7].to_i,
                            time[0..1].to_i, time[2..3].to_i, time[4..5].to_i)
    event_type_id = type_id
    selected_ans = analyzers.select {|a| a.event_id.to_s == id }
    if selected_ans.length == 0
      raise "new_event: id arg, #{id} " +
        "does not identify any known analyzer."
    else
      analyzer = selected_ans[0]
    end
#!!!!!!!!!!!!!!!!!!Replace with TradableEvent (model) when it's ready:
    TestTradableEvent.new(datetime, event_type_id, analyzer)
  end

  def new_parameter(name:, type_desc:, value:)
    result = FunctionParameter.new(name, type_desc, value)
    result
  end

  # A "new" "tradable_analyzer" with the specified name and id - retrieved
  # from the database if it can be found, otherwise, instantiated and saved
  # to the database.  (retrieves/creates TradableProcessorSpecification)
#!!!!!!!!!!!!!!!!!!finish/switch-to this or delete it!!!!!!!!!!
  def new_analyzer_or_maybe_not(name:, id:, period_type:)
    result = TradableProcessorSpecification.find(id)
    if result.nil? then
      ###!!!How to set event_generation_profile_id?!!!
      ###!!!Answer: Create the TPS somewhere else!!!!
#!!!      result = TradableProcessorSpecification.create!(processor_id: id,
#!!!        period_type: id_for(period_type))
    end
puts "TOF::new_analyzer - result: #{result.inspect}"
=begin
#!!!!Reminder: Might need to create this, too, and associate the two types.
    TradableAnalyzer.create!(name: name, event_id: id,
                             is_intraday: is_intraday(period_type))
=end
    result
  end

end
