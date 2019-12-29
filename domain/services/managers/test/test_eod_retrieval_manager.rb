require 'ruby_contracts'
require 'eod_retrieval_manager'
require 'test_eod_data_wrangler'

class TestEODRetrievalManager < EODRetrievalManager

  def send_TEST_eod_data_retrieval_run_state
    # null op
  end

  private

  attr_reader :continue_processing

  def prepare_for_main_loop(args = nil)
    if next_eod_check_key != nil then
      # Clean up leftover keys from previous run.
      while next_eod_check_key != nil do
        dequeue_eod_check_key
      end
    end
    super(args)
    @continue_processing = true
  end

  def wait_for_notification
    @eod_check_key = TEST_KEY
    # Publish, essentially, the 'TEST_KEY' and '@symbols' to my "self".
    queue_messages(@eod_check_key, @symbols)
    test "starting #{__method__} - q-count: #{queue_count(eod_check_key)}"
    test("#{__method__}#{$$} - test QUEUED: #{TEST_KEY}: #{@symbols}")
    @target_symbols_count = queue_count(@eod_check_key)
    enqueue_eod_check_key(@eod_check_key)
    test("#{__method__}#{$$} - test queued: #{@eod_check_key}")
    test "ending #{__method__} - q-count: #{queue_count(eod_check_key)}"
  end

  def new_data_wrangler
    test "starting #{__method__} - q-count: #{queue_count(eod_check_key)}"
    d = DateTime.now
    close = "#{d.year}-#{d.month}-#{d.day}"
    test "(#{$$}) #{__method__} - ec-key, cld: #{eod_check_key}, #{close}"
    TestEODDataWrangler.new(self, eod_check_key, close)
  end

  def post_process(args = nil)
    @continue_processing = false
    test "#{__method__} - tgtsymcount: #{target_symbols_count}"
    test "eod-chk-queue-contains(#{eod_check_key}): "\
      "#{eod_check_queue_contains(eod_check_key)}"
    test "ending #{__method__} - q-count: #{queue_count(eod_check_key)}"
  end

  def main_loop_cleanup(args = nil)
    test "starting #{__method__} - q-count: #{queue_count(eod_check_key)}"
    delete_queue(TEST_KEY)
    test "ending #{__method__} - q-count: #{queue_count(eod_check_key)}"
  end

  TEST_PREFIX = 'TEST_'
  TEST_PAUSE, TEST_KEY = 5, "#{TEST_PREFIX}eod-check-symbols"
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
