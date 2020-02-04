require 'set'
require 'ruby_contracts'
require 'concurrent-ruby'
require 'subscriber'
require 'service'
require 'service_tokens'
require 'tat_services_facilities'
require 'eod_data_wrangler'
require 'data_wrangler_handler'
require 'eod_retrieval_inter_communications'

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
  # Service-intercommunications manager:
  attr_reader :intercomm
  attr_reader :config

  #####  Callback to "configure" the EODDataWrangler

  pre  :good_wrangler do |w| w != nil && w.is_a?(EODDataWrangler) end
  post :configured do |r, w|
    ! (w.log.nil? || w.error_log.nil? || w.config.nil?) end
  post :intercomm_set do |r, wrangler|
    wrangler.intercomm == self.intercomm end
  def configure_wrangler(eod_wrangler)
    eod_wrangler.configure(log: log, elog: error_log, config: config)
    eod_wrangler.intercomm = intercomm
  end

  private

  ##### Hook method implementations

  # Check if there are any past "eod-check" notifications whose processing has
  # not been finished (for example, due to the EOD-retrieval process aborting
  # or being killed), retrieve the associated symbol list, and complete the
  # processing for those symbols (i.e.: handle unfinished processing).
  def prepare_for_main_loop(args = nil)
    eod_check_keys = intercomm.eod_check_keys
    log_key = "#{self.class}.#{__method__}".to_sym
    log_messages({log_key => "eod_check_keys: #{eod_check_keys}"})
    eod_check_keys.each do |key|
      @eod_check_key = key
      log_messages({log_key => "eod-check-key: #{eod_check_key}"})
      if @eod_check_key != nil then
        msg = "recovering '#{@eod_check_key}' at #{Time.now} (ERM)"
        debug(msg)
        log_messages({log_key => msg})
        # Terminate the orphaned EOD-retrieval process to prevent
        # conflict (Will block [with a default time limit] until
        # acknowledgement is received.):
        order_termination(eod_check_key)
        @target_symbols_count = intercomm.eod_symbols_count(eod_check_key)
        handle_data_retrieval
      else
        warn("#{__method__}: eod_check_key == nil")
      end
    end
  end

  def continue_processing
    o_r_state = ordered_eod_data_retrieval_run_state
    result = o_r_state != SERVICE_TERMINATED
    debug "#{__method__}: result: #{result} [orstate: #{o_r_state}]"
    result
  end

  def process(args = nil)
    wait_for_and_process_eod_event
    sleep MAIN_LOOP_PAUSE_SECONDS
  end

  ##### Implementation

  def wait_for_and_process_eod_event
    debug("#{__method__} - calling 'wait_for_notification")
    wait_for_notification
    if eod_check_key.nil? then
      error_msg = "failed to obtain 'EOD-check' key"
      error(error_msg)
      raise error_msg
    end
    debug("#{__method__} - calling 'handle_data_retrieval")
    handle_data_retrieval
  end

  post :target_symbols_count do ! target_symbols_count.nil? end
  post :key_set do eod_check_key != nil end
  def wait_for_notification
    debug("[#{self.class}.#{__method__}] subscribing to channel: " +
         "#{default_subscription_channel} (#{self.inspect})")
    subscribe_once do
      debug("#{__method__}: (in subscribe_once block) lastmsg: #{last_message}")
      @eod_check_key = last_message
    end
    debug("[#{self.class}.#{__method__}] end of method")
  end

  # Oversee the retrieval of EOD data for the symbols associated with
  # 'eod_check_key'.
  pre  :eod_check_key do eod_check_key != nil && ! eod_check_key.empty? end
  pre  :target_syms do
    target_symbols_count != nil && target_symbols_count >= 0 end
  post :empty_symlist_cleanup do implies(target_symbols_count == 0,
         ! intercomm.eod_check_queue_contains(eod_check_key)) end
  def handle_data_retrieval
    debug("#{self.class}.#{__method__}: target_symbols_count: "\
          "#{target_symbols_count}")
    if target_symbols_count > 0 then
      handler = DataWranglerHandler.new(service_tag, config)
      wrangler = new_data_wrangler
      wrangler.configure(log: log, elog: error_log, config: config)
      # Let the "data wrangler" do the actual data-retrieval work.
      handler.async.execute(wrangler)
    else
      # Ensure that potential recovery work does not see this
      # 'eod-check-key', since it has 0 associated symbols.
      intercomm.remove_from_eod_check_queue(eod_check_key)
    end
  end

  pre  :eod_check_key do eod_check_key != nil end
  post :result do |result| result != nil end
  def new_data_wrangler
    close = close_date(eod_check_key)
    debug("close for #{eod_check_key}: #{close.inspect}")
    if close.nil? then
      msg = "No close date found for '#{eod_check_key}'"
      error(msg)
      raise msg
    end
    EODDataWrangler.new(self, eod_check_key, close)
  end

  MAIN_LOOP_PAUSE_SECONDS = 15

  pre  :config_exists do |config| config != nil end
  post :log_config_etc_set do invariant end
  def initialize(config)
    @config = config
    @log = self.config.message_log
    @error_log = self.config.error_log
    @run_state = SERVICE_RUNNING
    @intercomm = EODRetrievalInterCommunications.new(owner: self,
        my_key_query: :eod_check_key)
    if @service_tag.nil? then
      @service_tag = EOD_DATA_RETRIEVAL
    end
    # Set up to log with the key 'service_tag'.
    self.log.change_key(service_tag)
    if @error_log.respond_to?(:change_key) then
      @error_log.change_key(service_tag)
    end
    initialize_message_brokers(@config)
    initialize_pubsub_broker(@config)
    set_subscription_callback_lambdas
    super(intercomm.subscription_channel)  # i.e., set subscribe channel
    create_status_report_timer
    @status_task.execute
  end

  post :subs_callbacks do subs_callbacks != nil end
  def set_subscription_callback_lambdas
    @subs_callbacks = {}
    @subs_callbacks[:postproc] = lambda do
      @target_symbols_count = intercomm.eod_symbols_count(eod_check_key)
      debug("[ERM] #{__method__} - tgtsymscnt: #{@target_symbols_count}")
    end
  end

end
