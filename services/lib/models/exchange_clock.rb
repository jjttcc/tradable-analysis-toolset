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
puts "exchanges_for @exfut.nil?: #{@exchanges_for_unix_time.nil?}"
STDOUT.flush    # Allow any debugging output to be seen.
    result = @exchanges_for_unix_time[close_time.to_i]
puts "exchanges_for returning: #{result.inspect}"
STDOUT.flush    # Allow any debugging output to be seen.
    result
  end

  # The active (used) symbols associated with the exchanges associated with
  # 'close_time' (datetime returned by 'next_close_time') - i.e., the
  # symbols associated with 'exchanges_for(close_time)'
  def symbols_for(close_time)
STDOUT.flush    # Allow any debugging output to be seen.
    exchanges = exchanges_for(close_time)
=begin
#!!!TO-DO: Implement this!!!!:
First draft of algorithm:
(create a map: exchange_id -> symbols_in_that_exchanges (Array))
(create a map: exchange_for: symbol -> exchange_that_owns_the_symbol)
(create a map: exchange_id -> symbols_in_that_exchanges (Array))
(create a map: exchange_id -> symbols_in_that_exchanges (Array))
profiles = AnalysisProfile.all.select do |p|
  p.in_use?
end
candidate_symbols = profiles.map do |p|
  p.symbol_list.symbols
end.flatten
result = candidate_symbols.select do |s|
  exchange_for.has_key(s)
end
=end
result = ['IBM', 'RHT']   #!!!!STUB!!!!
puts "symbols_for - result: #{result.inspect}"
STDOUT.flush    # Allow any debugging output to be seen.
    result
  end

  # Have any exchanges been updated, or new ones added, based on to the
  # last time 'exchanges' were initialized or the last time this method was
  # called - whichever happened last.
  # (If true, the 'exchanges' list is reloaded - reread from database.)
  # If a block is provided, it is "yield"ed to with each updated exchange,
  # if any.
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
puts "yielding to #{c} (init time:\n#{@initialization_time}"
STDOUT.flush    # Allow any debugging output to be seen.
puts "[before] His up-at time: #{c.updated_at}"
STDOUT.flush    # Allow any debugging output to be seen.
              yield(c)
puts "[after] His up-at time: #{c.updated_at}"
STDOUT.flush    # Allow any debugging output to be seen.
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

  # Have any exchanges been updated, or new ones added, based on to the
  # last time 'exchanges' were initialized or the last time this method was
  # called - whichever happened last.
  # (If true, the 'exchanges' list is reloaded - reread from database.)
  # If a block is provided, it is "yield"ed to with each updated exchange,
  # if any.
  post :exchanges_updated_iff_true do |result|
    implies(result, exchanges != nil) end
  post :init_time_updated_iff_true do |result|
    implies(result, initialization_time != nil) end
  def old___exchanges_updated?(&block)
    # Don't forget to check if new exchanges have been added, and if any
    # have been deleted.
    new_exchanges = Exchange.all
    result = new_exchanges.count != exchanges.count
    if ! result then
      new_exchanges.each do |e|
        if e.updated_since?(@initialization_time) then
          result = true
          if block_given? then
            yield(e)
e.reload
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

  # List of exchanges (from 'exchanges') that have been updated, if any
#!!!!Needed? - probably not!!!!!
  def updated_exchanges
    exchanges.select { |e| e.was_updated? }
  end

  # The earliest (future) closing time among 'exchanges'
  # nil if today is not a trading day for any of 'exchanges'
  def next_close_time
    result = nil
    if @closing_unix_times.nil? then
puts "@closing_unix_times was nil"
      @exchanges_for_unix_time = {}
      @closing_unix_times = []
      @time_for = {}
      exchanges.each do |e| e.update_current_local_time end
      exchanges.select { |e| puts "(#{e.name})"; e.is_open? }.each do |e|
puts "#{e.name} is open: #{e.is_open?}"
puts "#{e.name} is trading day: #{e.is_trading_day?}"
        close_time = e.closing_time
puts "#{e.name}'s close time: #{close_time}"
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
      end
    else
puts "@closing_unix_times was NOT nil"
    end
    @closing_unix_times.sort!
puts "EC.#{__method__} - ctimes:"
puts @closing_unix_times.inspect
puts "EC.#{__method__} - ex-for.count: #{@exchanges_for_unix_time.count}"
puts "EC.#{__method__} - ex-for:"
@exchanges_for_unix_time.keys.each do |time|
  puts "#{@time_for[time]}:"
  @exchanges_for_unix_time[time].each { |e| puts '   ' + e.inspect }
end
puts "timefor: #{@time_for.inspect}"
    if ! @time_for.empty? then
      result = @time_for[@closing_unix_times[0]]
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
fex = @exchanges[0]
lex = @exchanges[-1]
puts "FIRST exchange name, tz: #{fex.name}, #{fex.timezone}"
puts "FIRST exchange - current local_time: #{local_time(fex.timezone)}"
puts "LAST exchange name, tz: #{lex.name}, #{lex.timezone}"
puts "LAST exchange - current local_time: #{local_time(lex.timezone)}"
puts "EC - exchanges.count: #{@exchanges.count.inspect}"
puts "EC - exchanges: #{@exchanges.inspect}"
    @closing_times = nil
    @exchanges_for_unix_time = {}
  end

end
