require 'set'
require 'ruby_contracts'
require 'data_config'
require 'subscriber'
require 'redis_facilities'
require 'tat_util'
require 'service_tokens'
require 'tat_services_facilities'
require 'eod_data_wrangler'
require 'concurrent-ruby'

# Managers of EODDataWrangler object, allowing EOD data retrieval to occur
# in a separate child process - Example:
#   handler = DataWranglerHandler.new(service_tag, log)
#   wrangler = EODDataWrangler.new(...)
#   ...
#   handler.async.execute(wrangler)
class DataWranglerHandler
  include Concurrent::Async, Contracts::DSL, TatServicesFacilities

  public

  # Perform data polling/retrieval by calling 'wrangler.execute' within a
  # forked child process.  Note: Invoke this method via 'async' - e.g.:
  #   handler.async.execute(wrangler)
  def execute(wrangler)
    tries = 0
    loop do
      child = fork do
        wrangler.execute(@child_error_key, RETRY_TAG)
      end
      tries += 1
      status = Process.wait(child)
      if tries > RETRY_LIMIT then
        @log.warn("#{@tag}: " +
                  ": Retry limit reached (#{RETRY_LIMIT}) - aborting...")
        break
      end
      error_msg = retrieved_message(@child_error_key)
      if error_msg != nil then
        delete_message(@child_error_key)
        log_msg("#{@tag}: #{error_msg}")
        if error_msg[0..RETRY_TAG.length-1] == RETRY_TAG then
          log_msg("Retrying #{@tag} (for #{wrangler.target_symbols.inspect})")
        else
          log_msg("#{@tag}: Unrecoverable error")
          # Unrecoverable error - end loop.
          break
        end
      else
        @log.info("#{@tag}: succeeded (#{wrangler.target_symbols.inspect})")
        # error_msg.nil? implies success, end the loop.
        break
      end
      sleep RETRY_PAUSE
    end
  end

  private

  RETRY_PAUSE, RETRY_MINUTES_LIMIT = 15, 210
  RETRY_LIMIT = (RETRY_MINUTES_LIMIT * 60) / RETRY_PAUSE
  RETRY_TAG = 'retry'

  pre :good_args do |tg, lg| ! (tg.nil? || lg.nil?) end
  def initialize(svc_tag, the_log)
    @log = the_log
    @child_error_key = new_semi_random_key(svc_tag.to_s)
    @tag = svc_tag
    # Async initialization:
    super()
  end

  def log_msg(s)
    if @log != nil then
      @log.warn(s)
    end
  end

end


# Management of EOD data retrieval logic
# Subscribes to 'eod_check_channel' for "eod-check" notifications; obtains
# the current list of symbols to be checked and, for each symbol, s:
#   when the latest EOD data for s is ready:
#     retrieve the latest data for s
#     store the retrieved data in the correct location for s
# Saves the list of symbols for which data has been retrieved to the
# messaging system and publishes the key for that list to the
# "eod-data-ready" channel.
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
      handler = DataWranglerHandler.new(service_tag, log)
      wrangler = EODDataWrangler.new(self, eod_check_key, end_date)
      # Let the "data wrangler" do the actual data-retrieval work.
      handler.async.execute(wrangler)
    end
  end

  private

  post :target_symbols do ! target_symbols.nil? end
  post :key_set do eod_check_key != nil end
#!!!!QUESTION: What to do if 'last_message' is nil or empty?!!!!
  def wait_for_eod_request
    debug("#{self.class} subscribing to channel: " +
         "#{default_subscription_channel} (#{self.inspect})")
    subscribe_once do
#!!!!QUESTION: What to do if 'last_message' is nil or empty?!!!!
      @eod_check_key = last_message
    end
  end

  private  ### Hook method implementations

  # Finish up for 'wait_for_eod_request'.
  post :target_syms do target_symbols != nil && target_symbols.is_a?(Set) end
  def post_process_subscription(channel)
    @target_symbols = Set.new(retrieved_set(eod_check_key))
    log.debug("[ERM] #{__method__} - tgtsyms: #{@target_symbols.inspect}")
  end

  public

  attr_reader :eod_check_key, :log

  private

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
