
# Test-stub implementation of TAT::ExchangeClock
class TestExchangeClock
  include Contracts::DSL, TatUtil, TimeUtilities, TAT::ExchangeClock

  public

  #####  Access

  # Number of times 'next_close_time' has been called
  attr_reader :nct_count

  # Number of seconds to add to "now" to get the next close time
  attr_reader :added_close_seconds

  # Number of 'next_close_time' calls that will yield a valid (!nil) result
  attr_reader :next_close_time_limit

  def next_close_time
    if nct_count < next_close_time_limit then
      result = DateTime.current + added_close_seconds.seconds
      @nct_count += 1
    else
      result = nil
    end
    result
  end

  def exchanges_for(close_time)
    []
  end

  #####  Boolean queries

  def exchanges_updated?(&block)
    false
  end

  #####  State-changing operations

  def refresh_exchanges
    self.closing_unix_times = nil
  end

  TestTradableSymbol = Struct.new(:symbol, :exchange_id, :tracked)

  def symbols_for(close_time)
    test_symbols.map { |s| TestTradableSymbol.new(s, 1, true) }
  end

  protected ### Hook method implementations

  def tracked_tradables(exchngs = nil)
    []
  end

  def additional_close_seconds
    result = 60
    if is_i?(ENV[ADDEND_SECONDS]) then
      result = ENV[ADDEND_SECONDS].to_i
    end
    result
  end

  private

  ADDEND_SECONDS = "TEST_SECONDS"

  attr_reader :test_symbols

  pre  :log do |log| log != nil end
  post :invariant do invariant end
  def initialize(log:, symbols:, close_time_limit: 1)
    # Ensure invariant from TimeUtilities
    self.time_utilities_implementation = TimeUtil
    @test_symbols = []
    if symbols != nil then
      @test_symbols = symbols
    end
    @exchanges = []
    self.exchanges_for_unix_time = {}
    @log = log
    @nct_count = 0
    @next_close_time_limit = close_time_limit
    @added_close_seconds = additional_close_seconds
  end

end
