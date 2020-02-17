require 'ruby_contracts'
require 'error_log'
require 'service_tokens'
require 'tat_services_facilities'

# Execution of activities needed to monitor markets/exchanges for
# time-based events and trigger (by publishing an event-message) resulting
# actions - E.g., publishing an EOD-check-data message associated with
# tradables for exchange 'X', where 'X' has just closed
class ExchangeScheduleMonitor
  include Contracts::DSL, Service

  private

  # Service-intercommunications manager:
  attr_reader :intercomm

  ##### Hook method implementations

  # Perform any needed pre-processing.
  def prepare_for_main_loop(args = nil)
##!!!!!TO-DO: Check: Should '@continue_monitoring' be '@continue__processing'?
    @continue_monitoring = true
    send_status_info
  end

  def process(args = nil)
    @exchange_was_updated = false
    @next_close_time = exchange_clock.next_close_time
    if @next_close_time.nil? then
      # No markets are open today - pause for a "long" time before
      # checking again whether any markets have entered a new day within
      # their timezones.
      debug "exchange_clock.next_close_time returned nil"
      long_pause
    else
      check(@next_close_time != nil)
      debug("eom - @next_close_time: #{@next_close_time} (for " +
            "#{exchange_clock.exchanges_for(@next_close_time).map do |e|
              "#{e.name.inspect}/#{e.timezone.inspect}"
            end.join(", ")})")
      if wait_for_deadline_reached(@next_close_time) then
        process_close_time_event
      end
    end
  end

  # Assume that an exchange has just closed (i.e., @next_close_time has
  # just occurred) and take appropriate action.  If 'run_state' is
  # "running", call 'intercomm.send_check_notification'; otherwise, respond
  # accordingly (pause if "suspended", terminate if "terminated", etc.).
  pre  :next_cl_time do @next_close_time != nil end
  def process_close_time_event
    debug("(deadline was reached) run_state, SR: #{intercomm.run_state}")
    if intercomm.suspended? then
      debug("#{__method__} - suspended - waiting...")
      wait_for_resumption
      debug("#{__method__} - [suspended] FINISHED waiting")
    end
    if intercomm.terminated? then
      debug("#{__method__} - We've been terminated!")
      @continue_monitoring = false
    else
      check(intercomm.running?, "#{service_tag} is running")
      # This service is running and @next_close_time was reached, so
      # send a check-for-EOD-data notification to any subscribers.
      intercomm.send_check_notification(
        exchange_clock.symbols_for(@next_close_time), @next_close_time)
    end
  end

  #####  Implementation

  # Wait for the specified UTC-time/deadline to occur.  If it does occur,
  # return true.  "Wait" means to loop while the deadline has not yet
  # occurred and, within the loop, sleep for a while and then call
  # 'handle_exchange_updates' to check for relevant database changes.
  # Returning false implies that a relevant database change was detected,
  # and that 'exchange_clock.exchanges' was reloaded - i.e., is up to date.
  post :time_reached_unless_dead do |result, time|
    implies(result, time <= Time.current || intercomm.terminated?) end
  def wait_for_deadline_reached(utc_time)
    cancel_wait = false
    pause_counter = 0
    debug("[#{__method__}] time: #{Time.current}, deadline: #{utc_time}.")
    while !intercomm.terminated? && !cancel_wait && Time.current < utc_time do
      pause
      if pause_counter > CHECK_FOR_UPDATES_THRESHOLD then
        debug("It's #{Time.current} and I'm waiting for a deadline " +
              "of #{utc_time}.")
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
        debug("On #{Time.current} the database was changed, " +
              "so I'm ending my loop.")
      end
    end
    ! cancel_wait
  end

  # If this service is 'running', ask 'exchange_clock' whether the exchanges
  # need updating and, if so, call:
  #   exchange_clock.refresh_exchanges
  def handle_exchange_updates
    if intercomm.running? && exchange_clock.exchanges_updated?  then
      @exchange_was_updated = true
      exchange_clock.refresh_exchanges
    end
  end

  begin

    LONG_TERM_STATUS_ITERATIONS = 10

  # If this service is 'running': send status info to any interested parties;
  # otherwise, null op.
  def send_status_info
    if intercomm.running? then
      close_time = nil
      if @next_close_time != nil then
        close_time = @next_close_time.utc.to_s
      end
      intercomm.send_next_close_time(close_time)
      if
        @long_term_i_count < 0 ||
          @long_term_i_count > LONG_TERM_STATUS_ITERATIONS
      then
        @long_term_i_count = 0
        open_markets = @exchange_clock.open_exchanges.map do |m|
          m.name
        end
        intercomm.send_open_market_info(open_markets)
      end
      @long_term_i_count += 1
    end
  end

  end

  # Check if a new run-state has been ordered (by another service) and, if
  # it has and the new state is 'terminated', set 'continue_monitoring' to
  # false.
  post :termination_side_effect do
    implies(intercomm.terminated?, ! continue_monitoring) end
  def process_ordered_run_state
    intercomm.update_run_state
    if intercomm.terminated? then
      @continue_monitoring = false
    end
  end

  # Wait for an external order to end the suspended run-state.
  pre  :suspended      do intercomm.suspended? end
  post :not_suspended  do ! intercomm.suspended? end
  def wait_for_resumption
    while intercomm.suspended? do
      pause
    end
  end

  # Sleep for EXMON_PAUSE_SECONDS.
  def pause
    sleeptime = EXMON_PAUSE_SECONDS
    STDOUT.flush    # Allow any debugging output to be seen.
    sleep sleeptime
    send_status_info
    process_ordered_run_state
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
      process_ordered_run_state
      if intercomm.terminated? then
        # Allow this process to "die" ASAP.
        break
      end
    end
  end

  attr_reader :continue_monitoring, :exchange_clock, :refresh_requested

  # While this value is > the number of seconds until the next upcoming
  # market-close time, any new market/exchange updates will be ignored.
  EXCH_THRESHOLD_INTERVAL = 600
  # Number of pauses to occur before it's time to check for a database
  # update related to an Exchange:
  CHECK_FOR_UPDATES_THRESHOLD = 15

  pre  :config_exists do |config| config != nil end
  post :log_config_etc_set do invariant end
  post :ex_clock_type do exchange_clock.is_a?(TAT::ExchangeClock) end
  def initialize(config)
    @config = config
    @log = self.config.message_log
    @error_log = self.config.error_log
    @refresh_requested = false
    @exchange_clock = config.database::exchange_clock(@error_log)
    @intercomm = ExchangeMonitoringInterCommunications.new(self)
    @long_term_i_count = -1
    @service_tag = EOD_EXCHANGE_MONITORING
    # Set up to log with the key 'service_tag'.
    self.log.change_key(service_tag)
    if @error_log.respond_to?(:change_key) then
      @error_log.change_key(service_tag)
    end
    initialize_message_brokers(self.config)
    create_status_report_timer(status_manager: intercomm)
    @status_task.execute
  end

end
