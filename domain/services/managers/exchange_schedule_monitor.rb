require 'ruby_contracts'
require 'error_log'
require 'publisher'
require 'service_tokens'
require 'tat_services_facilities'


# Execution of activities needed to monitor markets/exchanges for
# time-based events and trigger (by publishing an event-message) resulting
# actions - E.g., publishing an EOD-check-data message associated with
# tradables for exchange 'X', where 'X' has just closed
class ExchangeScheduleMonitor < Publisher
  include Service

  public  ###  Basic operations

  def execute
    @continue_monitoring = true
    send_status_info
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
puts "eom - @next_close_time: #{@next_close_time} (for " +
"#{exchange_clock.exchanges_for(@next_close_time).map do |e|
  "#{e.name.inspect}/#{e.timezone.inspect}"
end.join(", ")})"
STDOUT.flush    # Allow any debugging output to be seen.
        # (Wait until it's '@next_close_time'.)
#!!!!Consider sending (queue_messages) the list of symbols and the
#!!!close-date (send_close_date) ahead of time for robustness -
#!!!If the process dies and is not restarted until after 'next_close_time'
#!!!occurs, then (on startup) retrieve the key (from where? - the message
#!!!broker?) and do the 'publish eod_check_key' again.
        time_to_send = deadline_reached(@next_close_time)
puts "eom: time_to_send: #{time_to_send}"
STDOUT.flush    # Allow any debugging output to be seen.
        if time_to_send then
          if run_state != SERVICE_RUNNING then
            if run_state == SERVICE_SUSPENDED then
              wait_for_resume_command
            end
          end
          if terminated? then
            @continue_monitoring = false
          else
            check(run_state == SERVICE_RUNNING, "#{service_tag} is running")
            # The service (this process) is running and it is "time-to-send",
            # so send a check-for-EOD-data notification to any subscribers.
            send_check_notification(
              exchange_clock.symbols_for(@next_close_time), @next_close_time)
          end
        end
      end
    end
  end

  private  ###  Implementation

  # Wait for the specified UTC-time/deadline to occur.  If it does occur,
  # return true.  "Wait" means to loop while the deadline has not yet
  # occurred and, within the loop, sleep for a while and then call
  # 'handle_exchange_updates' to check for relevant database changes.
  # Returning false implies that a relevant database change was detected,
  # and that 'exchange_clock.exchanges' was reloaded - i.e., is up to date.
  post :time_reached_unless_dead do |result, time|
    implies(result, time <= Time.current || terminated?) end
  def deadline_reached(utc_time)
    cancel_wait = false
    pause_counter = 0
    while ! terminated? && ! cancel_wait && Time.current < utc_time do
      pause
      if pause_counter > CHECK_FOR_UPDATES_THRESHOLD then
puts "It's #{Time.current} and I'm waiting for a deadline of #{utc_time}."
        handle_exchange_updates
        pause_counter = 0
      else
        pause_counter += 1
      end
      if
        @exchange_was_updated &&
        utc_time.to_i - Time.current.to_i >= EXCH_THRESHOLD_INTERVAL
      then
        cancel_wait = true
puts "On #{Time.current} the database was changed, so I'm ending my loop."
      end
    end
    ! cancel_wait
  end

  # If run_state == SERVICE_RUNNING, ask 'exchange_clock' whether the
  # exchanges need updating and, if so, call:
  #   exchange_clock.refresh_exchanges
  def handle_exchange_updates
    if run_state == SERVICE_RUNNING && exchange_clock.exchanges_updated?  then
puts "[heu] - ex_updated was true"
      @exchange_was_updated = true
      exchange_clock.refresh_exchanges
    end
  end

  begin

    LONG_TERM_STATUS_ITERATIONS = 10

  # If run_state == SERVICE_RUNNING: send status info to any interested
  # parties.  Otherwise, null op.
  def send_status_info
    if run_state == SERVICE_RUNNING then
      close_time = nil
      if @next_close_time != nil then
        close_time = @next_close_time.utc.to_s
      end
      send_next_close_time(close_time)
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
  end

  end

  # Retrieve any pending external commands and enforce a response by
  # changing internal state - @run_state.
  post :termination_side_effect do
    implies(terminated?, ! continue_monitoring) end
  def process_external_command
    new_state = ordered_eod_exchange_monitoring_run_state
    if new_state != nil && new_state != run_state then
      @run_state = new_state
      if terminated? then
        @continue_monitoring = false
        # Make sure the order doesn't "linger" after termination.
        delete_exch_mon_order
      end
    else
    end
  end

  # Wait for an external order to end the suspended run-state.
  pre  :suspended do run_state == SERVICE_SUSPENDED end
  post :not_susp  do run_state != SERVICE_SUSPENDED end
  def wait_for_resume_command
    while run_state == SERVICE_SUSPENDED
      pause
    end
  end

  # Generate a new 'eod_check_key' and send 'symbols', with the new key, as
  # well as the date part of 'closing_date_time'[1] (which is the closing
  # time of the exchange(s) associated with 'symbols'), to the messaging
  # system.  Then publish 'eod_check_key' on the EOD_CHECK_CHANNEL.
  # [1] The key for the closing-date is: "#{eod_check_key}:close-date"
  pre :symbols_array do |symbols| ! symbols.nil? && symbols.class == Array end
  def send_check_notification(symbols, closing_date_time)
    eod_check_key = new_eod_check_key
    if symbols.count > 0 then
      # Insurance - in case subscriber crashes while processing eod_check_key:
puts "enqueuing check key: #{eod_check_key}"
      enqueue_eod_check_key eod_check_key
      count = queue_messages(eod_check_key, symbols.map {|s| s.symbol},
                     DEFAULT_EXPIRATION_SECONDS)
      send_close_date(eod_check_key, closing_date_time)
      if count != symbols.count then
        msg = "send_check_notification: add_set returned different count " +
          "(#{count}) than the expected #{symbols.count} - symbols.first: " +
          symbols.first.symbol
        warn(msg)
      end
      publish eod_check_key
    end
  end

  # Sleep for EXMON_PAUSE_SECONDS.
  def pause
    sleeptime = EXMON_PAUSE_SECONDS
    STDOUT.flush    # Allow any debugging output to be seen.
    sleep  sleeptime
    send_status_info
    process_external_command
  end

  # Sleep for EXMON_LONG_PAUSE_ITERATIONS periods of EXMON_PAUSE_SECONDS.
  def long_pause
    sleeptime = EXMON_PAUSE_SECONDS
    pause_counter = 0
    EXMON_LONG_PAUSE_ITERATIONS.times do |i|
      STDOUT.flush    # Allow any debugging output to be seen.
      sleep sleeptime
      if pause_counter > CHECK_FOR_UPDATES_THRESHOLD then
        handle_exchange_updates
        pause_counter = 0
      else
        pause_counter += 1
      end
      send_status_info
      process_external_command
      if terminated? then
        break
      end
    end
  end

  private

  attr_reader :continue_monitoring, :exchange_clock, :refresh_requested

  # While this value is > the number of seconds until the next upcoming
  # market-close time, any new market/exchange updates will be ignored.
  EXCH_THRESHOLD_INTERVAL = 600
  # Number of pauses to occur before it's time to check for a database
  # update related to an Exchange:
  CHECK_FOR_UPDATES_THRESHOLD = 15

  pre  :config_exists do |config| config != nil end
  post :ex_clock_type do exchange_clock.is_a?(TAT::ExchangeClock) end
  def initialize(config)
    @refresh_requested = false
    @exchange_clock = config.database::exchange_clock
    @run_state = SERVICE_RUNNING
    @long_term_i_count = -1
    @service_tag = EOD_EXCHANGE_MONITORING
    initialize_message_brokers(config)
    initialize_pubsub_broker(config)
    create_status_report_timer
    super(EOD_CHECK_CHANNEL)
    @status_task.execute
  end

end
