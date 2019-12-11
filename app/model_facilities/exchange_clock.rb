require 'time_util'

# ActiveRecord-based implementation of TAT::ExchangeClock
class ExchangeClock
  include Contracts::DSL, TatUtil, TimeUtilities, TAT::ExchangeClock

  public

  #####  State-changing operations

  def refresh_exchanges
    exchanges.each do |e|
      e.reload
    end
    self.closing_unix_times = nil
  end

  protected ### Hook method implementations

  def tracked_tradables(exchngs = nil)
    result = TradableSymbol.tracked_tradables
    if exchngs != nil then
      log.debug("#{self.class}.#{__method__} - exchngs: #{exchngs}")
      # result = all "tracked-tradables" whose exchange is in 'exchngs'
      ex_id_map = Hash[exchngs.collect { |x| [x.id, true] } ]
      result = result.select do |s|
        ex_id_map[s.exchange_id]
      end
    end
    log.debug("#{self.class}.#{__method__} - result: #{result}")
    result
  end

  def all_exchanges
    Exchange.all
  end

  private

  pre  :log do |log| log != nil end
  post :invariant do invariant end
  def initialize(log)
    # Ensure invariant from TimeUtilities
    self.time_utilities_implementation = TimeUtil
    super(log)
  end

end
