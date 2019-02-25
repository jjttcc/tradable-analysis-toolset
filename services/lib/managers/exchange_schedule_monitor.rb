require 'ruby_contracts'
require 'error_log'
require 'publisher'
require 'tat_services_facilities'


# Execution of activities needed to monitor markets/exchanges for
# time-based events and trigger (by publishing an event-message) resulting
# actions - E.g., publishing an EOD-check-data message associated with
# tradables for exchange 'X', where 'X' has just closed
class ExchangeScheduleMonitor < Publisher
  include Contracts::DSL, RedisFacilities, TatServicesFacilities, TatUtil

  public  ###  Access

  attr_reader :eod_check_channel, :eod_data_ready_channel
  # List of symbols found to be "ready" upon 'eod_check_channel' notice:
  attr_reader :target_symbols

  public  ###  Basic operations

  def execute_eod_monitoring
    @continue_monitoring = true
    while continue_monitoring
      @exchange_was_updated = false
      @next_close_time = exchange_clock.next_close_time
      if @next_close_time.nil? then
        # No markets are open today - pause for a "long" time before
        # checking again whether any markets have entered a new day within
        # their timezones.
        long_pause
      else
        check(@next_close_time != nil)
puts "eom - @next_close_time: #{@next_close_time}"
STDOUT.flush    # Allow any debugging output to be seen.
        time_to_send = deadline_reached(@next_close_time)
puts "eom - time_to_send: #{time_to_send}"
STDOUT.flush    # Allow any debugging output to be seen.
        if time_to_send then
          # Send a check-for-EOD-data notification to any subscribers.
puts "calling symbols_for, send_check_notification " +
"with next-close-time: #{@next_close_time}"
STDOUT.flush    # Allow any debugging output to be seen.
          send_check_notification(exchange_clock.symbols_for(@next_close_time))
        end
      end
      # Force the next exchange_clock.next_close_time call to use
      # up-to-date data:
      exchange_clock.refresh_exchanges
    end
  end

  private  ###  Implementation

  # Wait for the specified UTC-time/deadline to occur.  If it does occur,
  # return true.  "Wait" means to loop while the deadline has not yet
  # occurred and, within the loop, sleep for a while and then call
  # 'handle_exchange_updates' to check for relevant database changes.
  # Returning false implies that a relevant database change was detected,
  # and that 'exchange_clock.exchanges' was reloaded - i.e., is up to date.
  post :time_reached do |res, time| implies(res, time <= Time.current) end
  def deadline_reached(utc_time)
    cancel_wait = false
    pause_counter = 0
    while ! cancel_wait && Time.current < utc_time
puts "[dr] It's #{Time.current} and I'm waiting for a deadline of #{utc_time}."
      pause
      if pause_counter > CHECK_FOR_UPDATES_THRESHOLD then
        handle_exchange_updates
        pause_counter = 0
      else
        pause_counter += 1
      end
      if
        @exchange_was_updated &&
        utc_time - Time.current >= EXCH_THRESHOLD_INTERVAL
      then
        cancel_wait = true
puts "On #{Time.current} the database was changed, so I'm ending my loop."
      end
    end
    ! cancel_wait
  end

  def handle_exchange_updates
    if exchange_clock.exchanges_updated?  then
puts "[heu] - ex_updated was true"
      @exchange_was_updated = true
      exchange_clock.refresh_exchanges
    end
  end

  begin

    LONG_TERM_STATUS_ITERATIONS = 10

  # Send status info to any interested parties.
  def send_status_info
    send_alive_status
    close_time = nil
    if @next_close_time != nil then
      close_time = @next_close_time.utc.to_s
    end
    send_next_close_time(close_time, EXCH_THRESHOLD_INTERVAL)
    if
      @long_term_i_count < 0 ||
      @long_term_i_count > LONG_TERM_STATUS_ITERATIONS
    then
      @long_term_i_count = 0
      open_markets = @exchange_clock.open_exchanges.map do |m|
        m.name
      end
      send_open_market_info(open_markets)
    end
    @long_term_i_count += 1
    @long_term_i_count += 1
  end

  # Send status info to any interested parties.
#!!!!Perhaps, also report which, if any, exchanges are currently open -
#!!!!possibly less often - i.e., in a separate method.
  def old___send_status_info
    alive_args = eval_settings(EXCH_MONITOR_ALIVE_SETTINGS)
puts "'send_status_info' sending: #{alive_args.inspect}"
    redis.set *alive_args
    close_time_replacement = nil
    if @next_close_time != nil then
      close_time_replacement = @next_close_time.utc.to_s
    end
    close_time_args = eval_settings(EXCH_MONITOR_NEXT_CLOSE_SETTINGS,
        close_time_replacement, EXCH_THRESHOLD_INTERVAL)
puts "'send_status_info' sending: #{close_time_args.inspect}"
    redis.set *close_time_args
    if
      @long_term_i_count < 0 ||
      @long_term_i_count > LONG_TERM_STATUS_ITERATIONS
    then
      @long_term_i_count = 0
      open_markets = @exchange_clock.open_exchanges.map do |m|
        m.name
      end
      open_market_args = eval_settings(EXCH_MONITOR_OPEN_MARKET_SETTINGS,
                                      open_markets)
      redis.del open_market_args.first  # Remove the old list, if any.
      if ! open_markets.empty? then
puts "'send_status_info' sending: #{open_market_args.inspect}"
        redis.sadd *open_market_args
      end
    end
    @long_term_i_count += 1
    @long_term_i_count += 1
  end

  end

  # Send an "I am still alive" signal to any interested parties.
  def old__remove____send_status_info
#!!!fix:!!!
    settings = EXCH_MONITOR_ALIVE_SETTINGS
    alive_args = [settings[ALIVE_KEY], settings[ALIVE_VALUE],
      settings[ALIVE_EXPIRE]]
    alive_args = eval_settings(EXCH_MONITOR_ALIVE_SETTINGS)
#!!![end]fix:!!!
=begin
consider:
  alive_args[1] = @next_close_time.utc
i.e., send next-close-time instead of current time.
=end
puts "I am alive args: #{alive_args.inspect}"
    redis.set *alive_args
  end

  # Obtain the symbols/tradables affected by the closing of the exchanges
  # in 'exch_symbol_map' (i.e., EOD-data will soon be available) and
  # give that list to the redis server with the 'eod_check_key'.  Then
  # publish (to the redis server) 'eod_check_key' on the
  # 'eod_check_channel'.
  pre :symbols_exist do |symbols| ! symbols.nil? end
  def send_check_notification(symbols)
puts "send_check_notification - sadding: #{eod_check_key}, #{symbols} " +
"(#{symbols.map {|s| s.symbol}}) on #{DateTime.current}"
    if symbols.count > 0 then
#!!!!!      count = redis.sadd(eod_check_key, symbols.map {|s| s.symbol})
      count = add_set(eod_check_key, symbols.map {|s| s.symbol})
      if count != symbols.count then
        msg = "send_check_notification: add_set returned different count " +
          "(#{count}) than the expected #{symbols.count} - symbols.first: " +
          symbols.first.symbol
        $log.warn(msg)
      end
puts "send_check_notification - publishing '#{eod_check_key}'"
      publish eod_check_key
    end
  end

  # Sleep for PAUSE_SECONDS.
  def pause
    sleeptime = PAUSE_SECONDS
puts "sleeping #{sleeptime} seconds..."
    STDOUT.flush    # Allow any debugging output to be seen.
    sleep  sleeptime
    send_status_info
print "woke up at: "
system('date')
  end

  # Sleep for LONG_PAUSE_ITERATIONS periods of PAUSE_SECONDS.
  def long_pause
    sleeptime = PAUSE_SECONDS
    pause_counter = 0
    LONG_PAUSE_ITERATIONS.times do |i|
puts "#{i}th pause for #{sleeptime} seconds..."
      STDOUT.flush    # Allow any debugging output to be seen.
      sleep sleeptime
      if pause_counter > CHECK_FOR_UPDATES_THRESHOLD then
        handle_exchange_updates
        pause_counter = 0
      else
        pause_counter += 1
      end
      send_status_info
    end
  end

  private

  attr_reader :eod_check_key, :log, :continue_monitoring, :exchange_clock,
    :refresh_requested

  PAUSE_SECONDS, LONG_PAUSE_ITERATIONS = 15, 7
  # While this value is > the number of seconds until the next upcoming
  # market-close time, any new market/exchange updates will be ignored.
  EXCH_THRESHOLD_INTERVAL = 600
  # Number of pauses to occur before it's time to check for a database
  # update related to an Exchange:
  CHECK_FOR_UPDATES_THRESHOLD = 5

  post :attrs_set do ! log.nil? end
  def initialize
    @log = ErrorLog.new
    @refresh_requested = false
    @eod_check_key = new_eod_check_key
    @exchange_clock = ExchangeClock.new
    @long_term_i_count = -1
    super(EOD_CHECK_CHANNEL)
  end

end
