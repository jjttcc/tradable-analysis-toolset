# Constants and other "facilities" used by/for the TAT services
#!!!!!NOTE: This file might belong somewhere else - not in .../redis!!!!!
module TatServicesFacilities
  include Contracts::DSL, RedisFacilities

  protected  ### time-related constants

  EXMON_PAUSE_SECONDS, EXMONLONG_PAUSE_ITERATIONS = 15, 7
  # Number of seconds of "margin" to give the exchange monitor before the
  # next closing time in order to avoid interfering with its operation:
  PRE_CLOSE_TIME_MARGIN = 300
  # Number of seconds of "margin" to give the exchange monitor after the
  # next closing time in order to avoid interfering with its operation:
  POST_CLOSE_TIME_MARGIN = 90

  protected  ### messaging-related constants, settings

  STATUS_KEY, STATUS_VALUE, STATUS_EXPIRE, EXPIRATION_KEY =
    :status, :value, :expire, :ex

  EXCH_MON_NAME                 = 'exchange-schedule monitor'
  EOD_CHECK_KEY_BASE            = 'eod-check-symbols'
  EOD_DATA_KEY_BASE             = 'eod-ready-symbols'
  EXCHANGE_MON_STATUS_KEY       = 'exchange-monitor-run-state'
  EXCHANGE_CLOSE_TIME_KEY       = 'exchange-next-close-time'
  OPEN_EXCHANGES_KEY            = 'exchange-open-exchanges'
  EXCHANGE_MONITOR_CONTROL_KEY  = 'exchange-monitor-control'
  EOD_CHECK_CHANNEL             = 'eod-checktime'
  EOD_DATA_CHANNEL              = 'eod-data-ready'
  ANALYSIS_REQUEST_CHANNEL      = 'analysis-requests'
  NOTIFICATION_CREATION_CHANNEL = 'notification-creation-requests'
  NOTIFICATION_DISPATCH_CHANNEL = 'notification-dispatch-requests'
  EXCH_MONITOR_STATUS_SETTINGS  = {
    STATUS_KEY    => EXCHANGE_MON_STATUS_KEY,
    STATUS_VALUE  => lambda {Time.now.utc.to_s},
    STATUS_EXPIRE => {EXPIRATION_KEY => EXMON_PAUSE_SECONDS + 1}
  }
  EXCH_MONITOR_NEXT_CLOSE_SETTINGS   = {
    STATUS_KEY    => EXCHANGE_CLOSE_TIME_KEY,
    # default:
    STATUS_VALUE  => 'no markets open today',
    STATUS_EXPIRE => {EXPIRATION_KEY => EXMON_PAUSE_SECONDS + 1}
  }
  EXCH_MONITOR_OPEN_MARKET_SETTINGS = {
    STATUS_KEY    => OPEN_EXCHANGES_KEY,
    STATUS_VALUE  => '',
    STATUS_EXPIRE => nil
  }

  protected  ### service-control commands, states, and utilities

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

  attr_reader :run_state

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

  # Current state ordered for the exchange monitor - nil if none
  def current_ordered_exch_mon_state
    command = retrieved_message(EXCHANGE_MONITOR_CONTROL_KEY)
    STATE_FOR_CMD[command]
  end

  # exchange-monitoring convenience command methods: order_exch_mon_suspension,
  # order_exch_mon_resumption, order_exch_mon_termination:
  { 'order_exch_mon_suspension' => SERVICE_SUSPEND,
    'order_exch_mon_resumption' => SERVICE_RESUME,
    'order_exch_mon_termination' => SERVICE_TERMINATE }.each do |m_name, state|
    define_method(m_name.to_sym) do
      set_message(EXCHANGE_MONITOR_CONTROL_KEY, state)
    end
  end

  # exchange-monitoring state-query methods: exch_mon_suspended,
  # exch_mon_running, exch_mon_terminated:
  { 'exch_mon_suspended' => SERVICE_SUSPENDED,
    'exch_mon_running' => SERVICE_RUNNING,
    'exch_mon_unresponsive' => nil,
    'exch_mon_terminated' => SERVICE_TERMINATED }.each do |m_name, state|
    define_method(m_name.to_sym) do
      result = false
      status = exch_mon_run_state
      if status.nil? || status.empty? then
        if state.nil? then
          result = true
        end
      else
        result = state != nil && state.to_s == status[0..state.length-1]
      end
      result
    end
  end

  # Delete the last exchange-monitoring-service control order.
  def delete_exch_mon_order
    delete_object(EXCHANGE_MONITOR_CONTROL_KEY)
  end

  protected  ### generated messaging-related constant-based key values

  # new key for symbol set associated with "check for eod data" notifications
  def new_eod_check_key
    EOD_CHECK_KEY_BASE + rand(1..9999999999).to_s
  end

  # new key for symbol set associated with eod-data-ready notifications
  def new_eod_data_ready_key
    EOD_DATA_KEY_BASE + rand(1..9999999999).to_s
  end

  protected  ## Application-related messaging

  # The current exchange-monitor 'run_state'
  def exch_mon_run_state
    retrieved_message(EXCHANGE_MON_STATUS_KEY)
  end

  # The next exchange closing time
  def next_exch_close_time
    retrieved_message(EXCHANGE_CLOSE_TIME_KEY)
  end

  # The next exchange closing time, as a DateTime object - nil if none has
  # been published or if it is in an invalid format
  def next_exch_close_datetime
    result = nil
    time_str = retrieved_message(EXCHANGE_CLOSE_TIME_KEY)
puts "time_str: #{time_str}"
    if time_str =~ /\d+-/ then
#y, m, d = time_str.split '-'
#Date.valid_date? y.to_i, m.to_i, d.to_i
      result = DateTime.parse(time_str)
    end
puts "result: #{result}"
    result
  rescue
    nil
  end

  # List of currently open exchanges
  post :array do |result| result != nil && result.class == Array end
  def open_market_info
    retrieved_set(OPEN_EXCHANGES_KEY)
  end

  # Send the current exchange-monitor 'run_state' (to the redis server).
  def send_exch_mon_run_state
    args = eval_settings(EXCH_MONITOR_STATUS_SETTINGS)
    args[1] = "#{run_state}@#{args[1]}"
puts "'send_exch_mon_run_state' sending: #{args.inspect}"  #!!!!
    set_message(args[0], *args[1..-1])
  end

  # Send the next exchange closing time (to the redis server).
  def send_next_close_time(time)
    args = eval_settings(EXCH_MONITOR_NEXT_CLOSE_SETTINGS, time)
puts "'send_next_close_time' sending: #{args.inspect}" #!!!!
    set_message(args[0], *args[1..-1])
  end

  # Send the specified list of open exchanges (to the redis server).
  pre :markets_exist do |open_markets| open_markets != nil end
  def send_open_market_info(open_markets)
    args = eval_settings(EXCH_MONITOR_OPEN_MARKET_SETTINGS,
                                     open_markets)
    key = args.first
    if open_markets.nil? || open_markets.empty? then
      # No open markets, so simply delete the set:
      delete_object(key)
    else
      replace_set(key, args.second)
    end
  end

  protected  ## Utilities

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
      result[expire] = {EXPIRATION_KEY => replacement_expiration_seconds}
    end
    # If the 'value' is a lambda/Proc, use its result:
    if result[value].respond_to?(:call) then
      result[value] = result[value].call
    end
    # If the expiration period is nil, no expiration is to be used:
    if result[expire].nil? then
      result.pop
    end
puts "eval_settings returning: #{result.inspect}"
    result
  end

  def log(msg, level = 'warn')
    case level.to_sym
    when :info
      $log.info(msg)
    when :debug
      $log.debug(msg)
    when :warn
      $log.warn(msg)
    when :error
      $log.error(msg)
    when :fatal
      $log.fatal(msg)
    when :unknown
      $log.unknown(msg)
    end
  end

  def debug(msg)
    $log.debug(msg)
  end

end

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
