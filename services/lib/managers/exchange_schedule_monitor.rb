require 'ruby_contracts'
require 'error_log'
require 'publisher'
require 'tat_services_facilities'


# Execution of activities needed to monitor markets/exchanges for
# time-based events and trigger (by publishing an event-message) resulting
# actions - E.g., publishing an EOD-check-data message associated with
# tradables for exchange 'X', where 'X' has just closed
#!!!!NOTE: This class might become specialized to only monitor for exchange
#!!!!closings and resulting EOD data checks (as opposed, e.g., to
#!!!!monitoring for, e.g., close of after-hours trading).
class ExchangeScheduleMonitor < Publisher
  include Contracts::DSL, TatServicesFacilities, TatUtil

  public  ###  Access

  attr_reader :eod_check_channel, :eod_data_ready_channel
  # List of symbols found to be "ready" upon 'eod_check_channel' notice:
  attr_reader :target_symbols

  public  ###  Basic operations

  def execute_eod_monitoring
    @continue_monitoring = true
    while continue_monitoring
      @exchange_was_updated = false
      next_close_time = exchange_clock.next_close_time
puts "[eem] just got a next close-time of #{next_close_time}"
      if next_close_time.nil? then
        # No markets are open today - pause for a "long" time before
        # checking again whether any markets have entered a new day within
        # their timezones.
        long_pause
      else
        check(next_close_time != nil)
puts "eom - next_close_time: #{next_close_time}"
STDOUT.flush    # Allow any debugging output to be seen.
        time_to_send = deadline_reached(next_close_time)
puts "eom - time_to_send: #{time_to_send}"
STDOUT.flush    # Allow any debugging output to be seen.
        if time_to_send then
          # Send a check-for-EOD-data notification to any subscribers.
puts "calling symbols_for, send_check_notification " +
"with next-close-time: #{next_close_time}"
STDOUT.flush    # Allow any debugging output to be seen.
          send_check_notification(exchange_clock.symbols_for(next_close_time))
        end
if time_to_send then
  puts "All is normal"
else
  puts "NOT sending - a change occurred!"
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
    while ! cancel_wait && Time.current < utc_time
puts "[dr] It's #{Time.current} and I'm waiting for a deadline of #{utc_time}."
      pause
      handle_exchange_updates
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

=begin
  def old3___execute_eod_monitoring
    @continue_monitoring = true
    @exchange_was_updated = false
    while continue_monitoring
      next_close_time = exchange_clock.next_close_time
      if next_close_time.nil? then
        # No markets are open today - pause for a "long" time before
        # checking again whether any markets have entered a new day within
        # their timezones.
        long_pause
      else
        while ! next_close_time.nil?
          if Time.current >= next_close_time then
            # Find out which Exchanges have just closed.
            current_exchange_set = exchange_clock.exchanges_for(next_close_time)
            # And then send a check for EOD-data notification to them.
            send_check_notification(current_exchange_set)
            # Cause this loop to terminate so that we can start all over -
            # A new next-close-time will be obtained, ...
            next_close_time = nil
          else
            # Kill some time - waiting for 'next_close_time' to occur.
            pause
            handle_exchange_updates
            if @exchange_was_updated then
              if next_close_time - Time.current >= EXCH_THRESHOLD_INTERVAL then
                # Force termination of the loop - the next
                # exchange_clock.next_close_time call will then have access
                # to the new information.
                next_close_time = nil
              end
            end
          end
        end
      end
    end
  end
=end

  def handle_exchange_updates
puts "[heu]"
    if exchange_clock.exchanges_updated? { |component| component.touch } then
puts "[heu] - ex_updated was true"
      @exchange_was_updated = true
      exchange_clock.refresh_exchanges
    end
  end

  def old___handle_exchange_updates
    if exchange_clock.exchanges_updated? then
      @exchange_was_updated = true
      exchange_clock.refresh_exchanges
    end
  end

=begin
  def old2___execute_eod_monitoring
    @continue_monitoring = true
    next_close_time = nil
    while continue_monitoring do
      if refresh_requested then
        exchange_clock.refresh_exchanges
        next_close_time = nil
      end
      if next_close_time.nil? then
        next_close_time = exchange_clock.next_close_time
      end
      if next_close_time.nil? then
        # No markets are open today - pause for a long time.
        long_pause
      elsif Time.current >= next_close_time then
        current_exchange_set = exchange_clock.exchanges_for(next_close_time)
        send_check_notification(current_exchange_set)
        next_close_time = nil # Indicate need for a new 'next_close_time'.
      end
      pause
      check_for_refresh_signal
      send_i_am_still_alive_signal
    end
  end

  def old___execute_eod_monitoring
    @continue_monitoring = true
    next_close_time = nil
    while continue_monitoring
      if false && refresh_requested then
puts "CALLING exclock.refresh_exchanges"
        exchange_clock.refresh_exchanges
        next_close_time = nil
      end
      if next_close_time.nil? then
puts "getting next_close_time..."
        next_close_time = exchange_clock.next_close_time
      end
puts "next_close_time: #{next_close_time.inspect}"
      if next_close_time.nil? then
        # No markets are open today - pause for a long time.
puts "Waiting for a market trading day to occur..."
        long_pause
      elsif Time.current >= next_close_time then
puts "X: #{Time.current} >= #{next_close_time}"
        current_exchange_set = exchange_clock.exchanges_for(next_close_time)
        send_check_notification(current_exchange_set)
        next_close_time = nil # Indicate need for a new 'next_close_time'.
puts "ces.count: #{current_exchange_set.count}"
puts "ces:"
current_exchange_set.each do |e|
puts e.inspect
end
      end
      pause
      check_for_refresh_signal
      send_i_am_still_alive_signal
    end
  end
=end

#!!!!!to-do:!!!!!
def send_i_am_still_alive_signal
end

  # Obtain the symbols/tradables affected by the closing of the exchanges
  # in 'exch_symbol_map' (i.e., EOD-data will soon be available) and
  # give that list to the redis server with the 'eod_check_key'.  Then
  # publish (to the redis server) 'eod_check_key' on the
  # 'eod_check_channel'.
  pre :symbols_exist do |symbols| ! symbols.nil? end
  def send_check_notification(symbols)
puts "send_check_notification - sadding: #{eod_check_key}, #{symbols} " +
"on #{DateTime.current}"
    if symbols.count > 0 then
      count = redis.sadd(eod_check_key, symbols)
      if count != symbols.count then
        msg = "send_check_notification: redis.sadd returned different count " +
          "(#{count}) than the expected #{symbols.count} - symbols.first: " +
          symbols.first
        $log.warn(msg)
puts msg
      end
      puts "send_check_notification - publishing '#{eod_check_key}'"
      publish eod_check_key
    end
  end

  # Check for external signal indicating that state data that this object
  # depends on needs to be re-read (reloaded).
#!!!!!!!!Can obj.updated_at > last(obj.updated_at) be used to check if,
#!!!!!!!!e.g., exchange/schedule/whatever has changed and thus "refreshing"
#!!!!!!!!is needed????!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!obsolete? - probably!!!!
  def check_for_refresh_signal
exchange_monitor_refresh_key = 'EXREFSTUB'
    signal = redis.get exchange_monitor_refresh_key
    if (signal != nil && ! signal.empty?)  || @here_already.nil? then #!!!!!stub, duh!!!!
      @refresh_requested = true
    end
@here_already = "x"
  end

  # Sleep for PAUSE_SECONDS.
  def pause
    sleeptime = PAUSE_SECONDS
puts "sleeping #{sleeptime} seconds..."
    STDOUT.flush    # Allow any debugging output to be seen.
    sleep  sleeptime
    send_i_am_still_alive_signal
print "woke up at: "
system('date')
  end

  # Sleep for LONG_PAUSE_ITERATIONS periods of PAUSE_SECONDS.
  def long_pause
    sleeptime = PAUSE_SECONDS
    LONG_PAUSE_ITERATIONS.times do |i|
puts "#{i}th pause for #{sleeptime} seconds..."
      STDOUT.flush    # Allow any debugging output to be seen.
      sleep  sleeptime
      handle_exchange_updates
      send_i_am_still_alive_signal
    end
  end

  private

  attr_reader :eod_check_key, :log, :continue_monitoring, :exchange_clock,
    :refresh_requested

  PAUSE_SECONDS = 15
  LONG_PAUSE_ITERATIONS = 7
  # While this value is > the number of seconds until the next upcoming
  # market-close time, any new market/exchange updates will be ignored.
  EXCH_THRESHOLD_INTERVAL = 600

  post :attrs_set do ! log.nil? end
  def initialize
    @log = ErrorLog.new
    @refresh_requested = false
    @eod_check_key = new_eod_check_key
    @exchange_clock = ExchangeClock.new
    super(EOD_CHECK_CHANNEL)
  end

end
