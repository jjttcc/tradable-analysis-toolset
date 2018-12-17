# Manufacturing of objects persistent objects that take part in
# interactions with the mas-client interface (i.e., MAS server)
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

  def new_parameter(name:, type_desc:, value:)
    result = FunctionParameter.new(name, type_desc, value)
    result
  end

end
