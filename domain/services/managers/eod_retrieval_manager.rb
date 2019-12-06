require 'set'
require 'ruby_contracts'
require 'concurrent-ruby'
require 'subscriber'
require 'service'
require 'service_tokens'
require 'tat_services_facilities'
require 'eod_data_wrangler'

#!!!!!TO-DO: Move this class to its own file!!!!!!
# Managers of EODDataWrangler object, allowing EOD data retrieval to occur
# in a separate child process - Example:
#   handler = DataWranglerHandler.new(service_tag, log)
#   wrangler = EODDataWrangler.new(...)
#   ...
#   handler.async.execute(wrangler)
#!!!!???Can this class be generalized to also handle EOD-data-ready ->
#!!!!!!!EventBasedTrigger processing?
class OldReplace__DataWranglerHandler
  include Concurrent::Async, Contracts::DSL, TatServicesFacilities

  public

  #####  State-changing operations

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
        warn("#{@tag}: Retry limit reached (#{RETRY_LIMIT}) - aborting...")
        break
      end
      error_msg = retrieved_message(@child_error_key)
      if error_msg != nil then
        delete_message(@child_error_key)
        warn("#{@tag}: #{error_msg}")
        if error_msg[0..RETRY_TAG.length-1] == RETRY_TAG then
          warn("Retrying #{@tag} (for #{wrangler.inspect})")
        else
          error("#{@tag}: Unrecoverable error")
          # Unrecoverable error - end loop.
          break
        end
      else
        info("#{@tag}: succeeded (#{wrangler.inspect})")
        # error_msg.nil? implies success, end the loop.
        break
      end
      sleep RETRY_PAUSE
    end
  end

  private

  ##### Implementation

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
    error_log.warn(s)
  end

end


# Management of EOD data retrieval logic
# Subscribes to EOD_CHECK_CHANNEL for "eod-check" notifications; obtains
# the current list of symbols to be checked and, for each symbol, s:
#   when the latest EOD data for s is ready:
#     retrieve the latest data for s
#     store the retrieved data in the correct location for s
# Saves the list of symbols for which data has been retrieved to the
# messaging system and publishes the key for that list to the
# EOD_DATA_CHANNEL.
class EODRetrievalManager < Subscriber
  include Service

  public

  #####  Access

  attr_reader :eod_check_key
  # List of symbols found to be "ready" upon EOD_CHECK_CHANNEL notice:
  attr_reader :target_symbols_count
  attr_reader :config

  #####  Callback to "configure" the EODDataWrangler

  pre  :good_wrangler do |w| w != nil && w.is_a?(EODDataWrangler) end
  post :configured do |r, w|
    ! (w.log.nil? || w.error_log.nil? || w.config.nil?) end
  def configure_wrangler(eod_wrangler)
    eod_wrangler.configure(log: log, elog: error_log, config: config)
  end

  private

  ##### Hook method implementations

  # Check if there are any past "eod-check" notifications whose processing has
  # not been finished (for example, due to the EOD-retrieval process aborting
  # or being killed), retrieve the associated symbol list, and complete the
  # processing for those symbols (i.e.: handle unfinished processing).
  def prepare_for_main_loop(args = nil)
    eod_check_keys = eod_check_contents
meth_key = "#{self.class}.#{__method__}".to_sym
log_messages({meth_key => "eod_check_keys: #{eod_check_keys}"})
    eod_check_keys.each do |key|
      @eod_check_key = key
log_messages({meth_key => "eod-check-key: #{eod_check_key}"})
      if @eod_check_key != nil then
        msg = "recovering '#{@eod_check_key}' at #{Time.now} (ERM)"
        error_log.warn(msg)
log_messages({meth_key => msg})
        # Terminate the orphaned EOD-retrieval process to prevent conflict:
#!!!!(Will block [with time-limit] until acknowledgement is received.)!!!!
        order_termination(eod_check_key)
        @target_symbols_count = queue_count(eod_check_key)
        handle_data_retrieval
      else
        error_log.warn("#{__method__}: eod_check_key == nil")
      end
    end
  end

  def continue_processing
    ordered_eod_data_retrieval_run_state != SERVICE_TERMINATED
  end

  def process(args = nil)
    wait_for_and_process_eod_event
    sleep MAIN_LOOP_PAUSE_SECONDS
  end

  ##### Implementation

  def wait_for_and_process_eod_event
    wait_for_notification
#!!!template method needed (eod_check_key -> xxx):
    if eod_check_key.nil? then
#!!!      error_msg = "failed to obtain <templated-label> key"
      error_msg = "failed to obtain 'EOD-check' key"
      error(error_msg)
      raise error_msg
    end
#!!!template method needed (handle_data_retrieval -> xxx):
    handle_data_retrieval
  end

  post :target_symbols_count do ! target_symbols_count.nil? end
#!!!templatize:
  post :key_set do eod_check_key != nil end
#!!!!QUESTION: What to do if 'last_message' is nil or empty?!!!!
  def wait_for_notification
    debug("[#{self.class}.#{__method__}] subscribing to channel: " +
         "#{default_subscription_channel} (#{self.inspect})")
    subscribe_once do
#!!!!QUESTION: What to do if 'last_message' is nil or empty?!!!!
log_messages({__method__.to_sym =>
              "(in subscribe_once block) lastmsg: #{last_message}"})
      @eod_check_key = last_message
    end
    debug("[#{self.class}#{__method__}] end of method")
  end

  # Oversee the retrieval of EOD data for the symbols associated with
  # 'eod_check_key'.
  pre  :eod_check_key do eod_check_key != nil && ! eod_check_key.empty? end
  pre  :target_syms do
    target_symbols_count != nil && target_symbols_count >= 0 end
  post :empty_symlist_cleanup do implies(target_symbols_count == 0,
         ! eod_check_queue_contains(eod_check_key)) end
  def handle_data_retrieval
    meth_key = "#{self.class}.#{__method__}".to_sym
log_messages({meth_key => "target_symbols_count: #{target_symbols_count}"})
    if target_symbols_count > 0 then
      end_date = close_date(eod_check_key)
      handler = DataWranglerHandler.new(service_tag, config)
      wrangler = EODDataWrangler.new(self, eod_check_key, end_date)
      wrangler.configure(log: log, elog: error_log, config: config)
      # Let the "data wrangler" do the actual data-retrieval work.
      handler.async.execute(wrangler)
    else
      # Ensure that potential recovery work does not see this
      # 'eod-check-key', since it has 0 associated symbols.
      remove_from_eod_check_queue(eod_check_key)
    end
  end

  MAIN_LOOP_PAUSE_SECONDS = 15

  pre  :config_exists do |config| config != nil end
  post :log_config_etc_set do invariant end
  def initialize(config)
    @config = config
    @log = self.config.message_log
    @error_log = self.config.error_log
    @run_state = SERVICE_RUNNING
    @service_tag = EOD_DATA_RETRIEVAL
    # Set up to log with the key 'service_tag'.
    self.log.change_key(service_tag)
    if @error_log.respond_to?(:change_key) then
      @error_log.change_key(service_tag)
    end
    initialize_message_brokers(@config)
    initialize_pubsub_broker(@config)
    set_subscription_callback_lambdas
    super(EOD_CHECK_CHANNEL)  # i.e., subscribe channel
    create_status_report_timer
    @status_task.execute
  end

  post :subs_callbacks do subs_callbacks != nil end
  def set_subscription_callback_lambdas
    @subs_callbacks = {}
    @subs_callbacks[:postproc] = lambda do
      @target_symbols_count = queue_count(eod_check_key)
      debug("[ERM] #{__method__} - tgtsymscnt: #{@target_symbols_count}")
    end
  end

end
