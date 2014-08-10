class TradableObjectFactory
  # A new TradableAnalyzer with the specified name and id
  def new_analyzer(name: name, id: id)
    TradableAnalyzer.new(name, id)
  end

  def new_event(name: name, id: id)
    TradableAnalyzer.new(name, id)
  end
end
