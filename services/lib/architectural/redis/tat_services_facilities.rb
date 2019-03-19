require 'error_log'

# Constants and other "facilities" used by/for the TAT services
# NOTE: Many of the methods defined here require one or both of the redis
# client attributes, @redis and @redis_admin, to exist.  This can be
# accomplished by calling 'init_redis_clients'.
#!!!!!NOTE: This file might belong somewhere else - not in .../redis!!!!!
module TatServicesFacilities
  include Contracts::DSL, RedisFacilities, ServiceTokens

  public

  # Tag identifying "this" service
  post :result_valid do |result|
    implies(result != nil, SERVICE_EXISTS[result]) end
  def service_tag
    nil   # Redefine, if appropriate.
  end

  protected  ### time-related constants

  EXMON_PAUSE_SECONDS, EXMON_LONG_PAUSE_ITERATIONS = 3, 35
  RUN_STATE_EXPIRATION_SECONDS, DEFAULT_EXPIRATION_SECONDS,
    DEFAULT_ADMIN_EXPIRATION_SECONDS = 15, 28800, 600
  # Number of seconds of "margin" to give the exchange monitor before the
  # next closing time in order to avoid interfering with its operation:
  PRE_CLOSE_TIME_MARGIN = 300
  # Number of seconds of "margin" to give the exchange monitor after the
  # next closing time in order to avoid interfering with its operation:
  POST_CLOSE_TIME_MARGIN = 90

  protected  ### messaging-related constants, settings

  STATUS_KEY, STATUS_VALUE, STATUS_EXPIRE, EXPIRATION_KEY =
    :status, :value, :expire, :ex

  EOD_CHECK_KEY_BASE            = 'eod-check-symbols'
  EOD_DATA_KEY_BASE             = 'eod-ready-symbols'
  EXCHANGE_CLOSE_TIME_KEY       = 'exchange-next-close-time'
  OPEN_EXCHANGES_KEY            = 'exchange-open-exchanges'
  # publish/subscribe channels
  EOD_CHECK_CHANNEL             = 'eod-checktime'
  EOD_DATA_CHANNEL              = 'eod-data-ready'
  ANALYSIS_REQUEST_CHANNEL      = 'analysis-requests'
  NOTIFICATION_CREATION_CHANNEL = 'notification-creation-requests'
  NOTIFICATION_DISPATCH_CHANNEL = 'notification-dispatch-requests'
  CLOSE_DATE_SUFFIX             = 'close-date'

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

  protected  ######## Service-control commands, states, and utilities ########

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
  def iamhiding___current_ordered_exch_mon_state
    command = retrieved_message(EXCHANGE_MONITOR_CONTROL_KEY)
    STATE_FOR_CMD[command]
  end

  # Is 'service' alive?
  pre :valid do |service| ServiceTokens::SERVICE_EXISTS[service] end
  post :clients_set do @redis != nil && @redis_admin != nil end
  def is_alive?(service)
    status = method("#{service}_run_state").call
    result = status =~ /^#{SERVICE_RUNNING}/ ||
      status =~ /^#{SERVICE_SUSPENDED}/
  end

  # query: ordered_<service>_run_state (last ordered run-state for <service>)
  [
    EOD_DATA_RETRIEVAL,
    EOD_EXCHANGE_MONITORING,
    MANAGE_TRADABLE_TRACKING
  ].each do |symbol|
    method_name = "ordered_#{symbol}_run_state".to_sym
    define_method(method_name) do
      command = retrieved_message(CONTROL_KEY_FOR[symbol], @redis_admin)
      STATE_FOR_CMD[command]
    end
  end

  # "order_<service>_run_state" commands
  [
    EOD_DATA_RETRIEVAL,
    EOD_EXCHANGE_MONITORING,
    MANAGE_TRADABLE_TRACKING
  ].each do |symbol|
    {
      :suspension  => SERVICE_SUSPEND,
      :resumption  => SERVICE_RESUME,
      :termination => SERVICE_TERMINATE
    }.each do |command, state|
      define_method("order_#{symbol}_#{command}".to_sym) do
        set_message(CONTROL_KEY_FOR[symbol], state,
            {EXPIRATION_KEY => DEFAULT_ADMIN_EXPIRATION_SECONDS}, @redis_admin)
      end
    end
  end

  # "<service>_run_state" queries
  [
    EOD_DATA_RETRIEVAL,
    EOD_EXCHANGE_MONITORING,
    MANAGE_TRADABLE_TRACKING
  ].each do |symbol|
    method_name = "#{symbol}_run_state".to_sym
    define_method(method_name) do
      result = retrieved_message(STATUS_KEY_FOR[symbol], @redis_admin)
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
  [
    EOD_DATA_RETRIEVAL,
    EOD_EXCHANGE_MONITORING,
    MANAGE_TRADABLE_TRACKING
  ].each do |symbol|
    m_name = "send_#{symbol}_run_state".to_sym
    key = STATUS_KEY_FOR[symbol]
    define_method(m_name) do |exp = RUN_STATE_EXPIRATION_SECONDS|
      begin
        expir_arg = {EXPIRATION_KEY => exp}
        value_arg = "#{run_state}@#{Time.now.utc}"
        set_message(key, value_arg, expir_arg, @redis_admin)
      rescue StandardError => e
        log.warn("exception in #{__method__}: #{e}")
      end
    end
  end

=begin
###OLD####
  # send_<service>_run_state reporting
  [
    EOD_DATA_RETRIEVAL,
    EOD_EXCHANGE_MONITORING,
    MANAGE_TRADABLE_TRACKING
  ].each do |symbol|
    settings_hash = DEFAULT_RUN_STATE_STATUS_SETTINGS
    settings_hash[STATUS_KEY] = STATUS_KEY_FOR[symbol]
    m_name = "send_#{symbol}_run_state".to_sym
puts "DEFINING #{m_name} with #{settings_hash}"
    key = STATUS_KEY_FOR[symbol]
#!!!!try: add expire arg, get rid of settings_hash!!!!
    define_method(m_name) do
      args = eval_settings(settings_hash)
      args[1] = "#{run_state}@#{args[1]}"
puts "#{m_name} set_message(#{key}, #{args[1..-1]})"
#!!      set_message(args[0], *args[1..-1])
      set_message(key, *args[1..-1])
    end
  end
=end

=begin
  def send_exch_mon_run_state
    args = eval_settings(EXCH_MONITOR_STATUS_SETTINGS)
    args[1] = "#{run_state}@#{args[1]}"
    set_message(args[0], *args[1..-1])
  end
=end

  # Delete the last exchange-monitoring-service control order.
  def delete_exch_mon_order
    delete_object(EXCHANGE_MONITOR_CONTROL_KEY, @redis_admin)
  end

  protected  ######## generated constant-based key values ########

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

  end

  protected  ######## Application-related messaging ########

  ### Service status/info queries messaging ###

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

  ### Service status/info reports ###

=begin
#!!!remove:
  # Send the current exchange-monitor 'run_state' (to the redis server).
  def hide_me____send_exch_mon_run_state  #!!!!!!<- rm
    args = eval_settings(EXCH_MONITOR_STATUS_SETTINGS)
    args[1] = "#{run_state}@#{args[1]}"
    set_message(args[0], *args[1..-1])
  end
=end

  # Send the next exchange closing time (to the redis server).
  def send_next_close_time(time)
    args = eval_settings(EXCH_MONITOR_NEXT_CLOSE_SETTINGS, time)
    set_message(args[0], *args[1..-1])
  end

  # Using 'key' as the base of the message key, send the date portion of the
  # specified exchange-closing-time (datetime) in 'yyyy-mm-dd' format.
  # The key value used will be "#{key}:close-date"
  def send_close_date(key, datetime)
    set_message("#{key}:#{CLOSE_DATE_SUFFIX}", datetime.to_date,
                {EXPIRATION_KEY => DEFAULT_EXPIRATION_SECONDS})
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
        log.warn("exception in #{__method__}: #{e}")
      end
    end
  end

  protected  ###  Initialization

  post :clients_set do @redis != nil && @redis_admin != nil end
  def init_redis_clients
    config = DataConfig.new(log)
    @redis = config.redis_application_client
    @redis_admin = config.redis_administration_client
  end

  protected  ## Logging

  # The 'log' object
  def log
    if $log.nil? then
      $log = ErrorLog.new
    end
    $log
  end

  pre :level_valid do |_, level|
    [:info, :debug, :warn, :error, :fatal, :unknown].include?(level.to_sym) end
  pre :msg_exists do |msg| msg != nil end
  def log_message(msg, level = 'warn')
    $log.method(level.to_sym).call(msg)
  end

  # Logging with category: info, debug, warn, error, fatal, unknown:
  [ :info, :debug, :warn, :error, :fatal, :unknown].each do |m_name|
    define_method(m_name) do |msg|
      log_message(msg, m_name)
    end
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
