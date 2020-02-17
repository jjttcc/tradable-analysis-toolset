require 'publisher'
require 'tat_services_facilities'

# Encapsulation of services intercommunications from the POV of
# exchange-schedule monitoring
class ExchangeMonitoringInterCommunications < Publisher
  include Contracts::DSL, ExchangeCommunicationsFacilities
  include TatServicesFacilities, ServiceStateFacilities

  public

  #####  Access

  attr_reader :publication_channel

  #####  Message-broker queue modification

  # Generate a new 'eod_check_key' and, via the message-broker:
  #   - Queue 'symbols' (with 'eod_check_key' as the queue key).
  #   - Store the 'closing_date_time'[1] (which is the closing time of
  #     the exchange(s) associated with 'symbols').
  #   - Publish the 'eod_check_key' on the EOD_CHECK_CHANNEL.
  # [1] The key for the closing-date is: "#{eod_check_key}:close-date"
  pre :syms_enu do |symbols| symbols != nil && symbols.is_a?(Enumerable) end
  def send_check_notification(symbols, closing_date_time)
    debug("#{__method__} - symbols & count: #{symbols}, #{symbols.count}")
    eod_check_key = new_eod_check_key
    if symbols.count > 0 then
      debug("enqueuing check key: #{eod_check_key}")
      # Insurance - in case subscriber crashes while processing eod_check_key:
      enqueue_eod_check_key eod_check_key
      # (Convert to an array of String:)
      syms = symbols.map {|s| s.symbol}
      debug "#{__method__}: queue_messages(#{eod_check_key}, #{syms})"
      count = queue_messages(eod_check_key, syms, DEFAULT_EXPIRATION_SECONDS)
      debug("calling 'send_close_date' with: #{closing_date_time}")
      send_close_date(eod_check_key, closing_date_time)
      if count != symbols.count then
        msg = "send_check_notification: add_set returned different count " +
          "(#{count}) than the expected #{symbols.count} - symbols.first: " +
          symbols.first.symbol
        warn(msg)
      end
      debug "#{__method__} - publishing #{eod_check_key}"
      publish eod_check_key
    end
  end

  #####  Message-broker state-changing operations

###!!!!!!TO-DO: Figure out if some of these methods should move
###!!!!!!       into ExchangeCommunicationsFacilities.

  # Send the next exchange closing time (to the message broker).
  def send_next_close_time(time)
    args = eval_settings(EXCH_MONITOR_NEXT_CLOSE_SETTINGS, time)
    set_message(args[0], *args[1..-1])
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

  protected

  attr_accessor :error_log

  def initialize(owner)
    # For 'debug', 'error', ...:
    self.error_log = owner.send(:error_log)
    @publication_channel = TatServicesConstants::EOD_CHECK_CHANNEL
    initialize_message_brokers(owner.send(:config))
    initialize_pubsub_broker(owner.send(:config))
    super(publication_channel)
    @run_state = SERVICE_RUNNING
    @service_tag = EOD_EXCHANGE_MONITORING
  end

end
