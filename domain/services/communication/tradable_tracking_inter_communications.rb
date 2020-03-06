
# Encapsulation of services intercommunications from the point-of-view of
# the "tradable-tracking" service
class TradableTrackingInterCommunications
  include Contracts::DSL
  include TatServicesFacilities, ServiceStateFacilities

  public  :eod_exchange_monitoring_unresponsive?,
    :eod_exchange_monitoring_terminated?, :eod_exchange_monitoring_suspended?

  public

  #####  Access - message-broker queries

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

  # Is the EOD-exchange-monitor service available? - I.e., is it "not
  # unresponsive" and "not terminated"?
  def eod_exchange_monitor_available
    ! eod_exchange_monitoring_unresponsive? &&
      ! eod_exchange_monitoring_terminated?
  end

  # Are all monitored exchanges currently closed?
  def markets_are_closed
    open_market_info.empty?
  end

  #####  Message-broker state-changing operations

  # Tell the exchange monitor to start running again.
  def wake_exch_monitor
    order_eod_exchange_monitoring_resumption
  end

  # Order the EOD-exchange-monitoring service to suspend itself and wait
  # for the suspension to occur.
  # If a block is provided (block_given? == true) and, after waiting, the
  # EOD-exchange-monitoring service is not yet suspended (after checking
  # 'check_limit' times whether the suspension has occurred, sleeping
  # 'sleep_seconds' seconds after each check), then:
  #    - The block is called with the total number of seconds waited and
  #      whether the EOD-exchange-service is unresponsive or terminated - i.e.:
  #        yield(waited_for, eod_exchange_monitoring_unresponsive?,
  #              eod_exchange_monitoring_terminated?)
  #    - Return to the calling method.
  def suspend_exchange_monitor(check_limit: 7, sleep_seconds: 2)
    if ! eod_exchange_monitoring_suspended? then
      order_eod_exchange_monitoring_suspension
      checks = 0
      while ! eod_exchange_monitoring_suspended? && checks < check_limit do
        # Loop until the reported state actually is "suspended".
        sleep sleep_seconds
        checks += 1
      end
      if ! eod_exchange_monitoring_suspended? then
        waited_for = checks * sleep_seconds
        if block_given?  then
          yield(waited_for, eod_exchange_monitoring_unresponsive?,
                eod_exchange_monitoring_terminated?)
        else
          warn "EOD exchange-monitor failed to suspend after "\
            "#{waited_for} seconds."
        end
      else
        debug "EOD exchange-monitor successfully suspended"
      end
    end
  end

  private

  #####  Implementation

  attr_accessor :error_log

  # List of currently open exchanges
  post :array do |result| result != nil && result.class == Array end
  def open_market_info
    retrieved_set(OPEN_EXCHANGES_KEY)
  end

  #####  Initialization

  def initialize(owner)
    # For 'debug', 'error', ...:
    self.error_log = owner.send(:error_log)
    initialize_message_brokers(owner.send(:config))
    @run_state = SERVICE_RUNNING
    @service_tag = MANAGE_TRADABLE_TRACKING
  end

end
