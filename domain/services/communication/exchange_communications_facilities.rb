
# Facilities used by the exchange-schedule-monitoring service to
# communicate with other services
module ExchangeCommunicationsFacilities
  include Contracts::DSL, TatServicesConstants, MessagingFacilities

  public

  ##### Queries

  # new key for symbol set associated with "check for eod data" notifications
  def new_eod_check_key
    EOD_CHECK_KEY_BASE + next_key_integer.to_s
  end

  ##### Message-broker state-changing operations

  # Add the specified EOD check key-value to the "EOD-check" key queue.
  def enqueue_eod_check_key(key_value)
    queue_messages(EOD_CHECK_QUEUE, key_value, DEFAULT_EXPIRATION_SECONDS)
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

  # Send the next exchange closing time (to the message broker).
  def send_next_close_time(time)
    args = eval_settings(EXCH_MONITOR_NEXT_CLOSE_SETTINGS, time)
    set_message(args[0], *args[1..-1])
  end

  private

  ##### Messaging-related constants, settings

  STATUS_KEY, STATUS_VALUE, STATUS_EXPIRE = :status, :value, :expire

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

  ##### Utilities

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

end
