class ConventionalDatabaseConfiguration
  def self.exchange_clock(log)
    @exchange_clock = ExchangeClock.new(log)
  end
end
