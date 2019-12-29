require 'concurrent'
require 'ruby_contracts'
require 'stderr_error_log'
require 'tat_services_constants'
require 'messaging_facilities'
require 'service_tokens'

# Constants and other "facilities" used by/for the TAT services
module TatServicesFacilities
  include Contracts::DSL
  include TatServicesConstants, MessagingFacilities, ServiceTokens

  public

  # Tag identifying "this" service
  post :result_valid do |result|
    implies(result != nil, SERVICE_EXISTS[result]) end
  def service_tag
    nil   # Redefine, if appropriate.
  end

  protected

  if $is_production_run.nil? then
    raise "Fatal: '$is_production_run' is nil or not defined."
  end

  ##### internal attributes/queries

  attr_reader :run_state, :log

  ##### time-related constants

  EXMON_PAUSE_SECONDS, EXMON_LONG_PAUSE_ITERATIONS = 3, 35
  RUN_STATE_EXPIRATION_SECONDS, DEFAULT_EXPIRATION_SECONDS,
    DEFAULT_ADMIN_EXPIRATION_SECONDS, DEFAULT_APP_EXPIRATION_SECONDS =
      15, 28800, 600, 120
  # Number of seconds of "margin" to give the exchange monitor before the
  # next closing time in order to avoid interfering with its operation:
  PRE_CLOSE_TIME_MARGIN = 300
  # Number of seconds of "margin" to give the exchange monitor after the
  # next closing time in order to avoid interfering with its operation:
  POST_CLOSE_TIME_MARGIN = 90
  # Default number of seconds to wait for a message acknowledgement before
  # giving up:
  MSG_ACK_TIMEOUT = 60  #!!!!tune!!!!

  ##### messaging-related constants, settings

  STATUS_KEY, STATUS_VALUE, STATUS_EXPIRE = :status, :value, :expire

=begin
#!!!!!!!cleanup/remove:
  EOD_CHECK_KEY_BASE            = 'eod-check-symbols'
  EOD_DATA_KEY_BASE             = 'eod-ready-symbols'
  EXCHANGE_CLOSE_TIME_KEY       = 'exchange-next-close-time'
  OPEN_EXCHANGES_KEY            = 'exchange-open-exchanges'
  # publish/subscribe channels
  EOD_CHECK_CHANNEL             = 'eod-checktime'
  EOD_DATA_CHANNEL              = 'eod-data-ready'
  TRIGGERED_EVENTS_CHANNEL      = 'triggering-completed'
  TRIGGERED_RESPONSE_CHANNEL    = 'trigger-response'
  NOTIFICATION_CREATION_CHANNEL = 'notification-creation-requests'
  NOTIFICATION_DISPATCH_CHANNEL = 'notification-dispatch-requests'
  STATUS_REPORTING_CHANNEL      = 'status-reporting'
  REPORT_RESPONSE_CHANNEL       = 'status-reporting-response'
=end

  CLOSE_DATE_SUFFIX             = 'close-date'

  EXCH_MONITOR_NEXT_CLOSE_SETTINGS   = {
    STATUS_KEY    => EXCHANGE_CLOSE_TIME_KEY,
    # default:
    STATUS_VALUE  => 'no markets open today',
    STATUS_EXPIRE => EXMON_PAUSE_SECONDS + 1
  }
  EXCH_MONITOR_OPEN_MARKET_SETTINGS = {
    STATUS_KEY    => OPEN_EXCHANGES_KEY,
    STATUS_VALUE  => '',
    STATUS_EXPIRE => nil
  }

  ######## Service-control commands, states, and utilities ########

  SERVICE_SUSPEND               = 'suspend'
  SERVICE_TERMINATE             = 'terminate'
  SERVICE_RESUME                = 'resume'
  SERVICE_SUSPENDED             = :suspended
  SERVICE_TERMINATED            = :terminated
  SERVICE_RUNNING               = :running
  STATE_FOR_CMD                 = {
    SERVICE_SUSPEND         => SERVICE_SUSPENDED,
    SERVICE_TERMINATE       => SERVICE_TERMINATED,
    SERVICE_RESUME          => SERVICE_RUNNING,
  }

  # Is the service suspended?
  def suspended?
    run_state == SERVICE_SUSPENDED
  end

  # Is the service terminated?
  def terminated?
    run_state == SERVICE_TERMINATED
  end

  # Is the service running?
  def running?
    run_state == SERVICE_RUNNING
  end

  # Is 'service' alive?
  pre :valid do |service| ServiceTokens::SERVICE_EXISTS[service] end
  def is_alive?(service)
    method_name = "#{service}_run_state"
    status = method(method_name).call
    result = !! (status =~ /^#{SERVICE_RUNNING}/ ||
                  status =~ /^#{SERVICE_SUSPENDED}/)  # (i.e., as boolean)
    debug("#{self}.#{__method__} - status from #{method_name}: " +
          "'#{status}', result: '#{result}'")
    result
  end

  # query: ordered_<service>_run_state (last ordered run-state for <service>)
  MANAGED_SERVICES.each do |symbol|
    method_name = "ordered_#{symbol}_run_state".to_sym
    define_method(method_name) do
      command = retrieved_message(CONTROL_KEY_FOR[symbol], true)
      STATE_FOR_CMD[command]
    end
  end

  # "order_<service>_<run-state>" commands
  MANAGED_SERVICES.each do |symbol|
    {
      :suspension  => SERVICE_SUSPEND,
      :resumption  => SERVICE_RESUME,
      :termination => SERVICE_TERMINATE
    }.each do |command, state|
      define_method("order_#{symbol}_#{command}".to_sym) do
        set_message(CONTROL_KEY_FOR[symbol], state,
            DEFAULT_ADMIN_EXPIRATION_SECONDS, true)
      end
    end
  end

  # "<service>_<run-state>?" queries - e.g., <service>_suspended?, ...
  MANAGED_SERVICES.each do |symbol|
    method_name = "#{symbol}_run_state".to_sym
    define_method(method_name) do
      result = retrieved_message(STATUS_KEY_FOR[symbol], true)
      result
    end
    # <service>_suspended?, <service>_running?, ... queries
    [
      SERVICE_SUSPENDED, SERVICE_RUNNING, :unresponsive, SERVICE_TERMINATED
    ].each do |state|
      state_query_name = "#{symbol}_#{state}?".to_sym
      define_method(state_query_name) do
        result = false
        status = method(method_name).call
        if status.nil? || status.empty? then
          if state == :unresponsive then
            result = true
          end
        else
          result = state.to_s == status[0..state.length-1]
        end
        result
      end
    end
  end

  # send_<service>_run_state reporting
  MANAGED_SERVICES.each do |symbol|
    m_name = "send_#{symbol}_run_state".to_sym
    key = STATUS_KEY_FOR[symbol]
    define_method(m_name) do |exp = RUN_STATE_EXPIRATION_SECONDS|
      begin
        value_arg = "#{run_state}@#{Time.now.utc}"
        set_message(key, value_arg, exp, true)
      rescue StandardError => e
        error_log.warn("exception in #{__method__}: #{e}")
      end
    end
  end

  # delete_<service>_order (delete last ordered run-state for <service>)
  MANAGED_SERVICES.each do |symbol|
    method_name = "delete_#{symbol}_order".to_sym
    define_method(method_name) do
      delete_object(CONTROL_KEY_FOR[symbol])
    end
  end

  ######## generated constant-based key values ########

  begin

    BOTTOM_KEY_INT, TOP_KEY_INT = 70_000, 99_999
    @@key_int_bank = []

    def next_key_int
      if @@key_int_bank.empty? then
        bank_size = TOP_KEY_INT - BOTTOM_KEY_INT + 1
        @@key_int_bank = (BOTTOM_KEY_INT...TOP_KEY_INT).to_a.sample(bank_size)
      end
      @@key_int_bank.pop
    end

    # new key for symbol set associated with "check for eod data" notifications
    def new_eod_check_key
      EOD_CHECK_KEY_BASE + next_key_int.to_s
    end

    # new key for symbol set associated with eod-data-ready notifications
    def new_eod_data_ready_key
      EOD_DATA_KEY_BASE + next_key_int.to_s
    end

    # A new, "semi-random", key starting with 'base'
    def new_semi_random_key(base)
      base + next_key_int.to_s
    end

  end

  ######## Application-related messaging ########

  ##### Service status/info queries messaging #####

  # The next exchange closing time
  def next_exch_close_time
    retrieved_message(EXCHANGE_CLOSE_TIME_KEY)
  end

  # The next exchange closing time, as a DateTime object - nil if none has
  # been published or if it is in an invalid format
  def next_exch_close_datetime
    result = nil
    time_str = retrieved_message(EXCHANGE_CLOSE_TIME_KEY)
    if time_str =~ /\d+-/ then
      result = DateTime.parse(time_str)
    end
    result
  rescue
    nil
  end

  # The close-date (exchange-closing date) based on 'key'
  # The key value used for the retrieval will be "#{key}:close-date"
  def close_date(key)
    retrieved_message("#{key}:#{CLOSE_DATE_SUFFIX}")
  end

  # List of currently open exchanges
  post :array do |result| result != nil && result.class == Array end
  def open_market_info
    retrieved_set(OPEN_EXCHANGES_KEY)
  end

  begin  ## EOD-data-related messaging ##

    # Add the specified EOD check key-value to the "EOD-check" queue.
    def enqueue_eod_check_key(key_value)
      queue_messages(EOD_CHECK_QUEUE, key_value, DEFAULT_EXPIRATION_SECONDS)
    end

    # Add the specified EOD data-ready key-value to the "EOD-data-ready" queue.
    def enqueue_eod_ready_key(key_value)
      queue_messages(EOD_READY_QUEUE, key_value, DEFAULT_EXPIRATION_SECONDS)
    end

    # Remove the head (i.e., next_eod_check_key) of the "EOD-check" queue.
    # Return the removed-value/former-head.
    def dequeue_eod_check_key
      remove_next_from_queue(EOD_CHECK_QUEUE)
    end

    # Remove the head (i.e., next_eod_ready_key) of the "EOD-data-ready" queue.
    # Return the removed-value/former-head.
    def dequeue_eod_ready_key
      remove_next_from_queue(EOD_READY_QUEUE)
    end

    # Remove all occurrences of 'value' from the "EOD-check" queue.
    # Return the number of removed elements.
    def remove_from_eod_check_queue(value)
      remove_from_queue(EOD_CHECK_QUEUE, value)
    end

    # Remove all occurrences of 'value' from the "EOD-data-ready" queue.
    # Return the number of removed elements.
    def remove_from_eod_ready_queue(value)
      remove_from_queue(EOD_READY_QUEUE, value)
    end

    # The next EOD check key-value - i.e., the value currently at the
    # head of the "EOD-check" queue.  nil if the queue is empty.
    def next_eod_check_key
      queue_head(EOD_CHECK_QUEUE)
    end

    # The next EOD data-ready key-value - i.e., the value currently at the
    # head of the "EOD-data-ready" queue.  nil if the queue is empty.
    def next_eod_ready_key
      queue_head(EOD_READY_QUEUE)
    end

    # The contents, in order, of the "EOD-check" queue
    def eod_check_contents
      queue_contents(EOD_CHECK_QUEUE)
    end

    # The contents, in order, of the "EOD-data-ready" queue
    def eod_ready_contents
      queue_contents(EOD_READY_QUEUE)
    end

    # Does the "EOD-check" queue contain 'value'?
    def eod_check_queue_contains(value)
      queue_contains(EOD_CHECK_QUEUE, value)
    end

    # Does the "EOD-data-ready" queue contain 'value'?
    def eod_ready_queue_contains(value)
      queue_contains(EOD_READY_QUEUE, value)
    end

  end

  ##### Service status/info reports #####

  # Send the next exchange closing time (to the message broker).
  def send_next_close_time(time)
    args = eval_settings(EXCH_MONITOR_NEXT_CLOSE_SETTINGS, time)
    set_message(args[0], *args[1..-1])
  end

  # Using 'key' as the base of the message key, send the date portion of the
  # specified exchange-closing-time (datetime) in 'yyyy-mm-dd' format.
  # The key value used will be "#{key}:close-date"
  def send_close_date(key, datetime)
    set_message("#{key}:#{CLOSE_DATE_SUFFIX}", datetime.to_date,
                DEFAULT_EXPIRATION_SECONDS)
  end

  # Send the specified list of open exchanges (to the message broker).
  pre :markets_exist do |open_markets| open_markets != nil end
  def send_open_market_info(open_markets)
    args = eval_settings(EXCH_MONITOR_OPEN_MARKET_SETTINGS, open_markets)
    key = args.first
    if open_markets.nil? || open_markets.empty? then
      # No open markets, so simply delete the set:
      delete_object(key)
    else
      replace_set(key, args.second)
    end
  end

  ##### EOD data retrieval -> triggering services communication #####

  begin

    EOD_FINISHED_SUFFIX = :finished
    EOD_COMPLETED_STATUS = ""
    EOD_TIMED_OUT_STATUS = :timed_out

    # Send status: EOD-data-retrieval completed successfully.
    def send_eod_retrieval_completed(key)
      completion_key = "#{key}:#{EOD_FINISHED_SUFFIX}"
      set_message(completion_key, EOD_COMPLETED_STATUS)
    end

    # Send status: EOD-data-retrieval ended without completing due to
    # time-out, with ":msg" (if not empty) appended.
    def send_eod_retrieval_timed_out(key, msg)
      completion_key = "#{key}:#{EOD_FINISHED_SUFFIX}"
      status_msg = EOD_TIMED_OUT_STATUS
      if msg != nil && ! msg.empty? then
        status_msg = "#{status_msg}:#{msg}"
      end
      set_message(completion_key, status_msg)
    end

    # Status reported by the EOD-data-retrieval service
    def eod_retrieval_completion_status(key)
      completion_key = "#{key}:#{EOD_FINISHED_SUFFIX}"
      result = retrieved_message(completion_key)
    end

    # Does the value returned by 'eod_retrieval_completion_status' indicate
    # that the retrieval completed successfully?
    def eod_retrieval_completed?(value)
      value == EOD_COMPLETED_STATUS
    end

    # Does the value returned by 'eod_retrieval_completion_status' indicate
    # that the retrieval timed-out before completion?
    def eod_retrieval_timed_out?(value)
      value =~ /^#{EOD_TIMED_OUT_STATUS}/
    end

  end

  ##### General messaging utilities #####

  # Send a "generic" application message ('msg'), using 'key', with
  # default expiration TTL.
  def send_generic_message(key, msg, exp = DEFAULT_APP_EXPIRATION_SECONDS)
    set_message(key, msg, exp)
  end

  # Delete the message with the specified key.
  def delete_message(key)
    delete_object(key)
  end

  ##### Generic service/process control utilities #####

  begin

    PROCTERM = :terminate

    # Order process termination via key "#{keybase}:#{PROCTERM}".
    # If acknowledgement_timeout > 0, wait (block) until the receiver of the
    # termination order has acknowledged (by clearing the associated value
    # [e.g., via clear_order(keybase)]) the termination order, or until
    # acknowledgement_timeout seconds elapses - whichever happens first.
    # Otherwise (acknowledgement_timeout <= 0), do not wait for confirmation.
    def order_termination(keybase, acknowledgement_timeout = MSG_ACK_TIMEOUT)
      key = "#{keybase}:#{PROCTERM}"
      send_generic_message(key, true)
      if acknowledgement_timeout > 0 then
        sleep 1
        secs_passed = 1
        until retrieved_message(key) != true.to_s ||
                secs_passed >= acknowledgement_timeout
          sleep 1
          secs_passed += 1
        end
      end
    end

    # Has process termination been ordered via key "#{keybase}:#{PROCTERM}"?
    # If 'clear', ensure the order is cleared (i.e., the next call to
    # 'termination_ordered' will return false) before returning.
    def termination_ordered(keybase, clear = false)
      value = retrieved_message("#{keybase}:#{PROCTERM}")
      result = value == 'true'
      if clear then
        clear_order(keybase)
      end
      result
    end

    # Clear the last order sent (e.g., by calling 'order_termination') via
    # key "#{keybase}:#{PROCTERM}"
    def clear_order(keybase)
      send_generic_message("#{keybase}:#{PROCTERM}", nil)
    end

  end

  ######## Utilities

  # Evaluation (Array) of the Hash 'settings_hash'
  def eval_settings(settings_hash, replacement_value = nil,
                    replacement_expiration_seconds = nil)
    _, value, expire = 0, 1, 2
    result = [settings_hash[STATUS_KEY], settings_hash[STATUS_VALUE],
              settings_hash[STATUS_EXPIRE]]
    if replacement_value != nil then
      result[value] = replacement_value
    end
    if replacement_expiration_seconds != nil then
      result[expire] = replacement_expiration_seconds
    end
    # If the 'value' is a lambda/Proc, use its result:
    if result[value].respond_to?(:call) then
      result[value] = result[value].call
    end
    # If the expiration period is nil, no expiration is to be used:
    if result[expire].nil? then
      result.pop
    end
    result
  end

  # Create the timer (task) responsible for periodic reporting of 'run_state'.
  post :task_exists do @status_task != nil end
  def create_status_report_timer(srvc_tag: service_tag,
            period_seconds: RUN_STATE_EXPIRATION_SECONDS - 1)
    @status_report_method = "send_#{srvc_tag}_run_state"
    @status_task = Concurrent::TimerTask.new(
          execution_interval: period_seconds) do |task|
      begin
        send(@status_report_method)
      rescue StandardError => e
        error_log.warn("exception in #{__method__}: #{e}")
      end
    end
  end

  # Timer task configured to run method 'mthd' every 'secs' seconds
  post :task_exists do |result| result != nil end
  def periodic_task(mthd:, secs:)
    result = Concurrent::TimerTask.new(
          execution_interval: secs) do |task|
      begin
        mthd.call
      rescue StandardError => e
        error_log.warn("exception in #{__method__}: #{e}")
      end
    end
  end

  ######## Logging

  LOGGING_TAGS = [:info, :debug, :test, :warn, :error, :fatal, :unknown]
  OPTIONAL_LOGGING_TAGS = [:info, :debug]

  # Object used for error logging
  def error_log
    # (Default to self.log - redefine if separate 'log' and 'error_log'
    # objects are needed.)
    self.log
  end

  # Log the specified error (or warning, info, ...) message.
  pre :level_valid do |_, level|
    LOGGING_TAGS.include?(level.to_sym) end
  pre :msg_exists do |msg| msg != nil end
  def log_error(msg, level = 'warn')
    error_log.method(level.to_sym).call(msg)
  end

  begin

    is_void = {}
    if $is_production_run then
      OPTIONAL_LOGGING_TAGS.each do |sym|
        is_void[sym] = true
      end
    end
    # Logging with category: info, debug, warn, ...:
    LOGGING_TAGS.each do |m_name|
      if is_void[m_name] then
        # (Define as a no-op.)
        define_method(m_name) {|dummy_arg| }
      else
        define_method(m_name) do |msg|
          log_error(msg, m_name)
        end
      end
    end

  end

end

=begin
#!!!!!!!cleanup/remove:
orig_verbose = $VERBOSE
# Suppress the constant re-initialization warnings for the block below:
$VERBOSE = nil

if ENV.has_key?('RAILS_ENV') && ENV['RAILS_ENV'] == 'test' then
  # This is a test.  This is only a test...
  # https://www.youtube.com/watch?v=eic8hJu0sQ8
  TatServicesFacilities::EOD_CHECK_CHANNEL          = 'eod-checktime-test'
  TatServicesFacilities::EOD_DATA_CHANNEL           = 'eod-data-ready-test'
  TatServicesFacilities::EOD_CHECK_KEY_BASE         = 'eod-check-symbols-test'
  TatServicesFacilities::EOD_DATA_KEY_BASE          = 'eod-ready-symbols-test'
  TatServicesFacilities::ANALYSIS_REQUEST_CHANNEL   = 'analysis-requests-test'
  TatServicesFacilities::NOTIFICATION_CREATION_CHANNEL =
    'notification-creation-requests-test'
  TatServicesFacilities::NOTIFICATION_DISPATCH_CHANNEL =
    'notification-dispatch-requests-test'
end

# And, of course, restore the re-initialization warnings:
$VERBOSE = orig_verbose
=end
