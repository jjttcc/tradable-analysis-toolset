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

  #####  Message-broker queue/state-changing operations

  # Generate a new 'eod_check_key' and, via the message-broker:
  #   - Queue 'symbols' (with 'eod_check_key' as the queue key).
  #   - Store the 'closing_date_time'[1] (which is the closing time of
  #     the exchange(s) associated with 'symbols').
  #   - Publish the 'eod_check_key' on the EOD_CHECK_CHANNEL.
  # [1] The key for the closing-date is: "#{eod_check_key}:close-date"
  pre :is_running do running? end
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

  private

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
