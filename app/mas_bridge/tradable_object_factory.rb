class TradableObjectFactory
  include TimePeriodTypeConstants

  # A new TradableAnalyzer with the specified name and id
  def new_analyzer(name: name, id: id, period_type: period_type)
    TradableAnalyzer.new(name, id, is_intraday(period_type))
  end

  def new_event(date: date, time: time, id: id, type_id: type_id,
                analyzers: analyzers)
    datetime = DateTime.new(date[0..3].to_i, date[4..5].to_i, date[6..7].to_i,
                             time[0..1].to_i, time[2..3].to_i, time[4..5].to_i)
    event_type_id = type_id
    selected_ans = analyzers.select {|a| a.id == id }
    if selected_ans.length == 0
      raise "new_event: id arg, #{id} " +
        "does not identify any known analyzer."
    else
      analyzer = selected_ans[0]
    end
    TradableEvent.new(datetime, event_type_id, analyzer)
  end

  def new_parameter(name: name, type_desc: type_desc, value: value)
    FunctionParameter.new(name, type_desc, value)
  end

end
