class ConventionalDatabaseConfiguration
  def self.exchange_clock
    @exchange_clock = ExchangeClock.new
  end
end
