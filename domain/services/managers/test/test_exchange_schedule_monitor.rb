require 'ruby_contracts'
require 'eod_retrieval_manager'
require 'test_eod_data_wrangler'

class TestExchangeScheduleMonitor < ExchangeScheduleMonitor
  include Publication, TatUtil
  # (Needed for 'dequeue_eod_check_key':)
  include EODCommunicationsFacilities

  public :config

  protected

  def send_TEST_exchange_schedule_monitor_run_state
    # null op
  end

  attr_reader :continue_processing, :symbols

  private

  def long_pause
    if @next_close_time.nil? then
      # (Implied: exchange_clock.next_close_time returned nil - we're
      # finished.)
      @continue_processing = false
    else
      super
    end
  end

  def post_process(args = nil)
    if self.continue_processing then
      test "#{self.class}.#{__method__} - continuing..."
    else
      test "#{self.class}.#{__method__}: checking data (symbols: #{symbols})"
      check_queue_status
      test "#{self.class}.#{__method__} - test run completed"
    end
  end

  # Check that the correct exchange/eod-related data were placed into the
  # message queue.
  def check_queue_status
    latest_key = dequeue_eod_check_key
    check latest_key != nil, 'Last queued check-key should not be nil.'
    test "First check passed - key: #{latest_key}"
    c = queue_count(latest_key)
    check c == symbols.count,
      "Count (#{c}) for #{latest_key} queue should be #{symbols.count}"
    test "Second check passed - symbols queue count: #{c}"
    queued_symbols = queue_contents(latest_key)
    symbols.each do |s|
      check queued_symbols.include?(s),
        "#{latest_key} queue should contain #{s}"
    end
    test "Third check passed - q'd syms: #{queued_symbols}"
  end

  TEST_PREFIX = 'TEST_'
  TEST_SERVICE_TAG = "#{TEST_PREFIX}#{EOD_EXCHANGE_MONITORING}".to_sym

  pre  :config_exists do |config| config != nil end
  def initialize(config, test_symbols = [])
    @service_tag = TEST_SERVICE_TAG
    # (Fulfil TatServicesFacilities.service_tag postcondition:)
    SERVICE_EXISTS[@service_tag] = true
    @config = config
    @log = self.config.message_log
    @error_log = self.config.error_log
    @refresh_requested = false
    @run_state = SERVICE_RUNNING
    @intercomm = ExchangeMonitoringInterCommunications.new(self)
    @long_term_i_count = -1
    self.log.change_key(service_tag)
    if @error_log.respond_to?(:change_key) then
      @error_log.change_key(service_tag)
    end
    initialize_message_brokers(self.config)
    initialize_pubsub_broker(self.config)
    @continue_processing = true
    if test_symbols.nil? || test_symbols.empty? then
      @symbols = []
      warn "Empty symbols list specified - test run will be null."
      exit 0
    else
      @symbols = test_symbols
    end
    @exchange_clock = TestExchangeClock.new(log: @error_log,
                                            symbols: test_symbols)
    test "#{__method__}#{$$} - service tag, syms: #{@service_tag}, #{@symbols}"
    @default_publishing_channel = EOD_CHECK_CHANNEL
    prepare_test
  end

  def prepare_test
    # Empty the queue, in case it has left-over garbage:
    report = "queued eod check keys, if any: "
    while (k = dequeue_eod_check_key) != nil
      report += "'#{k}' "
    end
    debug report
  end

end
