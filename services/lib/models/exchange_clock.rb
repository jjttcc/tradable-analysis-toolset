# Abstraction for time-based monitoring of exchanges (such as: When is the
# earliest upcoming market-closing time and which exchanges will close at
# that time?)
class ExchangeClock
  include Contracts::DSL, TatUtil

  public  ###  Access

  # All exchanges in the database
  attr_reader :exchanges

  # The date/time at which 'exchanges' was last initialized
  attr_reader :initialization_time

  # The exchanges associated with 'close_time' (datetime returned by
  # 'next_close_time')
  def exchanges_for(close_time)
    result = @exchanges_for_unix_time[close_time.to_i]
    result
  end

  # The active (used) symbols associated with the exchanges associated with
  # 'close_time' (datetime returned by 'next_close_time') - i.e., the
  # symbols associated with 'exchanges_for(close_time)'
  pre  :valid_time do |ctime| ctime != nil && ctime.respond_to?(:strftime) end
  post :exists do |result| ! result.nil? end
  def symbols_for(close_time)
STDOUT.flush    # Allow any debugging output to be seen.
    exchanges = exchanges_for(close_time)
    ex_id_map = Hash[exchanges.collect { |x| [x.id, true] } ]
    tracked = TradableSymbol.tracked_tradables
puts "tracked symbols count: #{tracked.count}"
    result = tracked.select do |s|
print "looking for exchange for #{s.symbol} (xid: #{s.exchange_id}):\n" +
ex_id_map[s.exchange_id].inspect
      ex_id_map[s.exchange_id]
    end
if result.empty? then
  ['IBM', 'RHT'].each do |s|   #!!!!testing STUB!!!!
    ts = TradableSymbol.find_by_symbol(s)
    if ! ts.nil? then
      result << ts
      puts "[symbols_for] cheated - added #{ts.symbol}"
    end
  end
end
    result
  end

  # Have any exchanges been updated, or new ones added, based on to the
  # last time 'exchanges' were initialized or the last time this method was
  # called - whichever happened last.
  # (If true, the 'exchanges' list is reloaded - reread from database.)
  # If a block is provided, it is "yield"ed to with each updated exchange,
  # if any, and that exchange's components.
  post :exchanges_updated_iff_true do |result|
    implies(result, exchanges != nil) end
  post :init_time_updated_iff_true do |result|
    implies(result, initialization_time != nil) end
  def exchanges_updated?(&block)
    new_exchanges = Exchange.all
    result = new_exchanges.count != exchanges.count
    if ! result || block_given? then
      new_exchanges.each do |e|
        changed_components = e.updated_components(@initialization_time)
        if changed_components.count > 0 then
          result = true
          if block_given? then
            changed_components.each do |c|
              yield(c)
            end
            # (Don't break - need to yield all updated exchanges.)
          else
            break
          end
        end
      end
    end
    if result then
      # Since there was an update, update stuff...
      @exchanges = new_exchanges
      @initialization_time = DateTime.current
    end
    result
  end

  # The earliest (future) closing time among 'exchanges'
  # nil if today is not a trading day for any of 'exchanges'
  def next_close_time
    result = nil
    now = DateTime.current
    if @closing_unix_times.nil? then
      @exchanges_for_unix_time = {}
      @closing_unix_times = []
      @time_for = {}
      exchanges.each do |e| e.update_current_local_time end
      exchanges.select { |e| e.is_trading_day? }.each do |e|
        close_time = e.closing_time
        if close_time > now then
          unix_close_time = close_time.to_i
          if @exchanges_for_unix_time.has_key?(unix_close_time) then
            @exchanges_for_unix_time[unix_close_time] << e
          else
            @exchanges_for_unix_time[unix_close_time] = [e]
            @time_for[unix_close_time] = close_time
          end
          @closing_unix_times = @exchanges_for_unix_time.keys
          @closing_unix_times.each do |t|
            @time_for
          end
        else
          $log.debug("close_time for #{e.name} is past (#{close_time})")
        end
      end
    else
    end
    @closing_unix_times.sort!
    if ! @time_for.empty? then
      result = @time_for[@closing_unix_times[0]]
    end
    result
  end

  # All elements of 'exchanges' that are currently open
  # Note: This operation is somewhat expensive.
  def open_exchanges
    # Make sure each exchange's "current local time" is actually current:
    refresh_exchanges
    result = exchanges.select do |e|
      e.is_open?
    end
    result
  end

  public  ###  Basic operations

  def refresh_exchanges
    exchanges.each do |e|
      e.reload
    end
    @closing_unix_times = nil
  end

  private

  post :exchanges_set do ! exchanges.nil? end
  def initialize
    @exchanges = Exchange.all
    @initialization_time = DateTime.current
    @closing_times = nil
    @exchanges_for_unix_time = {}
  end

end
