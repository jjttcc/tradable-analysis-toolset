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

  def tracked_tradables(exchanges = nil)
puts "#{self.class}.[tracked_tradables] called"
    result = TradableSymbol.tracked_tradables
    if exchanges != nil then
      # result = all "tracked-tradables" whose exchange is in 'exchanges'
      ex_id_map = Hash[exchanges.collect { |x| [x.id, true] } ]
      result = result.select do |s|
        ex_id_map[s.exchange_id]
      end
    end
puts "#{self.class}.[tracked_tradables] returning #{result.inspect}"
    result
  end

  def all_exchanges
    new_exchanges = Exchange.all
  end

  private

  post :exchanges_set do ! exchanges.nil? end
  post :invariant do invariant end
  def initialize
    # Ensure invariant from TimeUtilities
    self.time_utilities_implementation = TimeUtil
    @exchanges = Exchange.all
    @initialization_time = current_date_time
    @closing_times = nil
    super
  end

end
