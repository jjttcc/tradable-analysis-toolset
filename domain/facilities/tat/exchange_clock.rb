# Abstraction for time-based monitoring of exchanges (such as: When is the
# earliest upcoming market-closing time and which exchanges will close at
# that time?)
module TAT
  module ExchangeClock
    include Contracts::DSL

    public

    #####  Access

    # All exchanges in the database
    attr_reader :exchanges

    # The date/time at which 'exchanges' was last initialized
    attr_reader :initialization_time


    # The earliest (future) closing time among 'exchanges'
    # nil if today is not a trading day for any of 'exchanges'
    def next_close_time
      result = nil
      now = current_date_time
      if closing_unix_times.nil? then
        self.exchanges_for_unix_time = {}
        self.closing_unix_times = []
        self.time_for = {}
        exchanges.each do |e| e.update_current_local_time end
        exchanges.select { |e| e.is_trading_day? }.each do |e|
          close_time = e.closing_time
          if close_time > now then
            unix_close_time = close_time.to_i
            if exchanges_for_unix_time.has_key?(unix_close_time) then
              exchanges_for_unix_time[unix_close_time] << e
            else
              exchanges_for_unix_time[unix_close_time] = [e]
              time_for[unix_close_time] = close_time
            end
            self.closing_unix_times = exchanges_for_unix_time.keys
          else
            log.debug("close_time for #{e.name} is past (#{close_time})")
          end
        end
      else
      end
      closing_unix_times.sort!
      if ! time_for.empty? then
        result = time_for[closing_unix_times[0]]
      end
      result
    end

    # The exchanges associated with 'close_time' (datetime returned by
    # 'next_close_time') - nil if there are no exchanges for 'close_time'
    pre  :time_exists do |close_time| close_time != nil end
    pre  :close_toi do |close_time| close_time.respond_to?(:to_i) end
    post :enumerable do |result|
      implies(result != nil, result.is_a?(Enumerable)) end
    post :holds_exchanges do |res| implies(res != nil && res.count > 0,
                                     res.first.is_a?(TAT::Exchange)) end
    def exchanges_for(close_time)
      exchanges_for_unix_time[close_time.to_i]
    end

    # The active (used) symbols associated with the exchanges associated with
    # 'close_time' (datetime returned by 'next_close_time') - i.e., the
    # symbols associated with 'exchanges_for(close_time)'
    pre  :valid_time do |ctime| ctime != nil && ctime.respond_to?(:strftime) end
    pre  :close_toi do |close_time| close_time.respond_to?(:to_i) end
    post :exists do |result| ! result.nil? && result.is_a?(Enumerable) end
    def symbols_for(close_time)
      result = []
      exchngs = exchanges_for(close_time)
      if exchngs != nil then
       result = tracked_tradables(exchngs)
      end
      log.debug("#{__method__} - close_time, result: #{close_time}, #{result}")
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
      log.debug("#{__method__} - result: #{result}")
      result
    end

    #####  Boolean queries

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
      new_exchanges = all_exchanges
      result = new_exchanges.count != exchanges.count
      if ! result || block_given? then
        new_exchanges.each do |e|
          changed_components = e.updated_components(initialization_time)
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
        self.initialization_time = current_date_time
      end
      result
    end

    #####  State-changing operations

    # Reload 'exchanges' from the database.
    post :closing_ux_times_nil do closing_unix_times.nil? end
    def refresh_exchanges
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    protected

    attr_accessor :closing_unix_times,
    # Hash-table: key: closing-(unix)time, value: list of Exchange
      :exchanges_for_unix_time
    attr_writer :initialization_time
    attr_reader :log

    protected ### Hook methods

    # If exchanges != nil, list of symbols identifying all currently tracked
    # tradables that are associated with an element (Exchange) of exchanges.
    # Otherwise (exchanges.nil), list of symbols identifying all tradables
    # that are currently being "tracked"
    post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
    post :empty_if_0_exchanges do |result| implies(exchanges != nil &&
        exchanges.count == 0, result != nil && result.count == 0) end
    def tracked_tradables(exchngs = nil)
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    # All stored Exchange objects
    post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
    post :exchanges do |res|
      implies(res.count > 0, res.first.is_a?(TAT::Exchange)) end
    def all_exchanges
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    private

    attr_accessor :time_for

    pre  :log do |log| log != nil end
    post :exchanges_set do ! exchanges.nil? end
    post :exchanges_for_utime_set do ! exchanges_for_unix_time.nil? end
    def initialize(log)
      self.exchanges_for_unix_time = {}
      @log = log
      self.initialization_time = current_date_time
      @exchanges = all_exchanges
    end

  end
end
