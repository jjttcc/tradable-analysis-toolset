require 'set'
require 'ruby_contracts'
require 'data_config'
require 'subscriber'
require 'redis_facilities'
require 'tat_util'
require 'service_tokens'
require 'tat_services_facilities'
require 'eod_data_wrangler'


# Management of EOD data retrieval logic
# Subscribes to 'eod_check_channel' for "eod-check" notifications; obtains
# the current list of symbols to be checked and, for each symbol, s:
#   if the latest EOD data for s is ready:
#     retrieve the latest data for s
#     store the retrieved data in the correct location for s
# Publishes the list of symbols for which data has been retrieved and
# stored to the "eod-data-ready" channel.
class EODRetrievalManager < Subscriber
  include Contracts::DSL, RedisFacilities, TatServicesFacilities

  public  ###  Access

  attr_reader :update_error, :eod_check_channel, :eod_data_ready_channel,
    :service_tag
  # List of symbols found to be "ready" upon 'eod_check_channel' notice:
  attr_reader :target_symbols

  public  ###  Basic operations

  def execute
    while ordered_eod_data_retrieval_run_state != SERVICE_TERMINATED
      wait_for_and_process_eod_event
      sleep MAIN_LOOP_PAUSE_SECONDS
    end
  end

  def wait_for_and_process_eod_event
    wait_for_eod_request
    if eod_check_key.nil? then
      error_msg = "failed to obtain 'EOD-check' key"
      error(error_msg)
      raise error_msg
    end
    if target_symbols.count > 0 then
      end_date = close_date(eod_check_key)
      wrangler = EODDataWrangler.new(target_symbols, eod_check_key,
                                     end_date, log) do |w|
#!!!!        w.init_redis_clients(self)
      end
#!!!!wrangler.add_observer(self)
      # Let the "data wrangler" do the actual data-retrieval work.
      wrangler.execute
    end
  end

#!!!!!!!!!!!!!!!!!REMOVE:!!!!!!!!!!!!!!!!!!!
  protected #!!!????????????????????!!!
  # Notify me/self (child thread/data-wrangler).
  def notify_from_thread(time, result, exception)
    msg = "#({time}) wrangler thread update: "
    if result.nil? then
      msg += "error: #{exception} (#{exception.class})"
      log.warn(msg)
    else
      msg += "result: #{result.inspect}"
      log.info(msg)
    end
  end

  alias_method :update, :notify_from_thread
  #!!!!!!!!!!!!!!!!![end] REMOVE!!!!!!!!!!!!!!!!!!!

  private

  post :target_symbols do ! target_symbols.nil? end
  post :key_set do eod_check_key != nil end
  def wait_for_eod_request
log.debug("subscribing to channel: " + default_subscription_channel +
    " #{DateTime.now} (#{self.inspect})")
STDOUT.flush
    info("#{self.class} subscribing to channel: " +
         "#{default_subscription_channel} (#{self.inspect})")
log.debug("subsc - redis: #{@redis}")
    subscribe_once do
      @eod_check_key = last_message
    end
  end

  private  ### Hook method implementations

  # Finish up for 'wait_for_eod_request'.
  post :target_syms do target_symbols != nil && target_symbols.is_a?(Set) end
  def post_process_subscription(channel)
    @target_symbols = Set.new(retrieved_set(eod_check_key))
  end

  private

  attr_reader :eod_check_key, :log

  RETRY_WAIT_SECONDS, MAIN_LOOP_PAUSE_SECONDS = 50, 15
  RUN_STATE_TTL = 300

  require 'logger'

  post :log do log != nil end
  def initialize(the_log = nil)
    @log = the_log
    if @log.nil? then
      @log = Logger.new(STDOUT)
    end
    $log = @log
    data_config = DataConfig.new(log)
    @update_error = false
    @run_state = SERVICE_RUNNING
    @service_tag = EOD_DATA_RETRIEVAL
    init_redis_clients
    super(EOD_CHECK_CHANNEL)  # i.e., subscribe channel
    # Create an alternate Redis for the timer to avoid conflict with
    # Redis subscriptions.
    create_status_report_timer
    @status_task.execute
  end

end
