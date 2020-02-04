# !!!??require 'time_util'
# !!!??require 'active_support/time'

# Test implementation of TAT::ExchangeClock
class TestExchangeClock
  include Contracts::DSL, TatUtil, TimeUtilities, TAT::ExchangeClock

  public

  #####  Access

  # Number of times 'next_close_time' has been called
  attr_reader :nct_count

  # Number of 'next_close_time' calls that will yield a valid (!nil) result
  attr_reader :next_close_time_limit

  def next_close_time
    if nct_count < next_close_time_limit then
      result = DateTime.current + 1.minute
      @nct_count += 1
    else
      result = nil
    end
    result
  end

  def exchanges_for(close_time)
####!!!!!!!!!!!!!!!!!!??????:!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!???:
    []
  end

  #####  Boolean queries

  ###!!!!!!???:
  def exchanges_updated?(&block)
    false
  end

  #####  State-changing operations

#!!!!!!TO-DO: change/adjust/...!!!!

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

###!!!!!??:
##  def all_exchanges
##    Exchange.all
##  end

  private

  attr_reader :test_symbols

  pre  :log do |log| log != nil end
  post :invariant do invariant end
  def initialize(the_log, symbols, close_time_limit = 1)
    # Ensure invariant from TimeUtilities
    self.time_utilities_implementation = TimeUtil
    @test_symbols = []
    if symbols != nil then
      @test_symbols = symbols
    end
    @exchanges = []
    self.exchanges_for_unix_time = {}
    @log = the_log
#!!!!??:    super(the_log)
    @nct_count = 0
    @next_close_time_limit = close_time_limit
  end

end
