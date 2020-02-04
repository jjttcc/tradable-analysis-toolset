require 'ruby_contracts'
require 'eod_retrieval_manager'
require 'test_eod_data_wrangler'

class TestEODRetrievalManager < EODRetrievalManager
  include Publication, TatUtil

  def send_TEST_eod_data_retrieval_run_state
    # null op
  end

  private

  attr_reader :continue_processing

  def prepare_for_main_loop(args = nil)
    if intercomm.next_eod_check_key != nil then
      # Clean up leftover keys from previous test run.
      while intercomm.next_eod_check_key != nil do
        intercomm.dequeue_eod_check_key
      end
    end
    super(args)
    @continue_processing = true
  end

  def wait_for_notification
    # Pretend to be external service outputting the symbols list:
    queue_messages(TEST_EOD_CHECK_KEY, @symbols)
    test "starting #{__method__} - q-count: #{queue_count(TEST_EOD_CHECK_KEY)}"
    test("#{__method__}#{$$} - test QUEUED: #{TEST_EOD_CHECK_KEY}: #{@symbols}")
    @target_symbols_count = queue_count(TEST_EOD_CHECK_KEY)
    # Pretend to be external service queueing the eod-check key:
    intercomm.enqueue_eod_check_key(TEST_EOD_CHECK_KEY)
    # Publish the 'TEST_EOD_CHECK_KEY' to my "self":
    child = fork do
      sleep 0.75    # Wait to try to make sure subscription occurs.
      publish TEST_EOD_CHECK_KEY, intercomm.subscription_channel
    end
    Process.detach(child)
    super   # (Subscribe to the above-scheduled publication.)
    test("#{__method__}#{$$} - test queued: #{TEST_EOD_CHECK_KEY}")
    test "ending #{__method__} - q-count: #{queue_count(TEST_EOD_CHECK_KEY)}"
  end

  def new_data_wrangler
    test "starting #{__method__} - q-count: #{queue_count(TEST_EOD_CHECK_KEY)}"
    d = DateTime.now
    close = "#{d.year}-#{d.month}-#{d.day}"
    test "(#{$$}) #{__method__} - ec-key, cld: #{TEST_EOD_CHECK_KEY}, #{close}"
    TestEODDataWrangler.new(self, TEST_EOD_CHECK_KEY, close)
  end

  def post_process(args = nil)
    @continue_processing = false
    test "#{__method__} - tgtsymcount: #{target_symbols_count}"
    test "eod-chk-queue-contains(#{eod_check_key}): "\
      "#{intercomm.eod_check_queue_contains(eod_check_key)}"
    test "ending #{__method__} - q-count: #{queue_count(eod_check_key)}"
  end

  def main_loop_cleanup(args = nil)
    test "starting #{__method__} - q-count: #{queue_count(eod_check_key)}"
    delete_queue(TEST_EOD_CHECK_KEY)
    test "ending #{__method__} - q-count: #{queue_count(eod_check_key)}"
  end

  TEST_PREFIX = 'TEST_'
  TEST_PAUSE, TEST_EOD_CHECK_KEY = 5, "#{TEST_PREFIX}eod-check-symbols"
  TEST_SERVICE_TAG = "#{TEST_PREFIX}#{EOD_DATA_RETRIEVAL}".to_sym

  pre  :config_exists do |config| config != nil end
  def initialize(config, test_symbols = [])
    @service_tag = TEST_SERVICE_TAG
    SERVICE_EXISTS[@service_tag] = true
    super(config)
    if test_symbols.nil? || test_symbols.empty? then
      @symbols = ['IBM', 'AAPL']
    else
      @symbols = test_symbols
    end
    test "#{__method__}#{$$} - service tag, syms: #{@service_tag}, #{@symbols}"
  end

end
