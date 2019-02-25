# Constants and other "facilities" used by/for the TAT services
#!!!!!NOTE: This file might belong somewhere else - not in .../redis!!!!!
module TatServicesFacilities
  protected

  STATUS_KEY, STATUS_VALUE, STATUS_EXPIRE = :status, :value, :expire
  EXPIRATION_KEY = :ex

  public  ### messaging-related constants

  EOD_CHECK_CHANNEL             = 'eod-checktime'
  EOD_DATA_CHANNEL              = 'eod-data-ready'
  EOD_CHECK_KEY_BASE            = 'eod-check-symbols'
  EOD_DATA_KEY_BASE             = 'eod-ready-symbols'
  EXCHANGE_MON_ALIVE_KEY        = 'exchange-monitor-alive'
  EXCHANGE_CLOSE_TIME_KEY       = 'exchange-next-close-time'
  OPEN_EXCHANGES_KEY            = 'exchange-open-exchanges'
  ANALYSIS_REQUEST_CHANNEL      = 'analysis-requests'
  NOTIFICATION_CREATION_CHANNEL = 'notification-creation-requests'
  NOTIFICATION_DISPATCH_CHANNEL = 'notification-dispatch-requests'
  EXCH_MONITOR_ALIVE_SETTINGS   = {
    STATUS_KEY    => EXCHANGE_MON_ALIVE_KEY,
    STATUS_VALUE  => lambda {Time.now.utc.to_s},
    STATUS_EXPIRE => {EXPIRATION_KEY => 60}
  }
  EXCH_MONITOR_NEXT_CLOSE_SETTINGS   = {
    STATUS_KEY    => EXCHANGE_CLOSE_TIME_KEY,
    # default:
    STATUS_VALUE  => 'no markets open today',
    STATUS_EXPIRE => nil
  }
  EXCH_MONITOR_OPEN_MARKET_SETTINGS = {
    STATUS_KEY    => OPEN_EXCHANGES_KEY,
    STATUS_VALUE  => '',
    STATUS_EXPIRE => nil
  }

  public  ### messaging-related constant-based key values

  # new key for symbol set associated with "check for eod data" notifications
  def new_eod_check_key
    EOD_CHECK_KEY_BASE + rand(1..9999999999).to_s
  end

  # new key for symbol set associated with eod-data-ready notifications
  def new_eod_data_ready_key
    EOD_DATA_KEY_BASE + rand(1..9999999999).to_s
  end

  protected  ## Application-related messaging

  def send_alive_status
    args = eval_settings(EXCH_MONITOR_ALIVE_SETTINGS)
puts "'send_alive_status' sending: #{args.inspect}"  #!!!!
    set_message(args[0], args[1..-1])
  end

  def send_next_close_time(time, expiration_seconds)
    args = eval_settings(EXCH_MONITOR_NEXT_CLOSE_SETTINGS,
                                    time, expiration_seconds)
puts "'send_next_close_time' sending: #{args.inspect}" #!!!!
    set_message(args[0], args[1..-1])
  end

  def send_open_market_info(open_markets)
    args = eval_settings(EXCH_MONITOR_OPEN_MARKET_SETTINGS,
                                     open_markets)
    key = args.shift
    # If open_markets.empty?, we intentionally replace with an empty set.
    replace_set(key, args)
  end

  def orig___send_open_market_info(open_markets)
    args = eval_settings(EXCH_MONITOR_OPEN_MARKET_SETTINGS,
                                     open_markets)
    key = args.shift
    delete_object(key) # Remove the old list, if any.
    if ! open_markets.empty? then
puts "'send_open_market_info' sending: #{key}, #{args.inspect}"  #!!!!
      add_set(key, args)
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

  protected

  def set_message(key, args)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  def add_set(key, args)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  def delete_object(key)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
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
