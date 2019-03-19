require 'set'
require 'ruby_contracts'
require 'data_config'
require 'subscriber'
require 'publication'
require 'redis_facilities'
require 'service_tokens'
require 'tat_util'
require 'tat_services_facilities'
require 'concurrent-ruby'

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#!!!!!!!!TO-DO: Move this class into a separate file.!!!!!!!!
# Objects responsible for, once an eod-check-symbols signal has been
# received (i.e., it's time to check if data is ready for the "target
# symbols"), managing the polling of the data provider and, when data is
# found to be available, updating the application's data store with the new
# EOD data
# Note: This class is a TimerTask.  The updating work is triggered by
# calling 'execute', which causes the 'perform_update' method to be invoked
# periodically (every SECONDS_BETWEEN_UPDATE_TRIES seconds).
# 'perform_update' will continue to do the polling and updating work (i.e.,
# retrieving the latest available data for each tradable identified by
# 'target_symbols' and storing it) each time it is called until all needed
# data has been retrieved/updated, at which point the thread (TimerTask)
# shuts itself down.
class EODDataWrangler < Concurrent::TimerTask
  include Contracts::DSL, Publication, TatServicesFacilities, TatUtil

  public

  attr_reader :data_ready_key, :eod_check_key, :target_symbols
  attr_reader :update_error, :update_symbol_count

  private

  pre  :remaining_symbols_set do ! @remaining_symbols.nil? end
  pre  :invariant do invariant end
  post :invariant do invariant end
  def perform_update(task)
    if
      ! update_completed &&
        @update_retries <= UPDATE_RETRY_LIMIT
    then
      @update_retries += 1
      old_sym_count = update_symbol_count
      update_eod_data
      if update_symbol_count != old_sym_count then
log.debug("#{__method__}: #{update_symbol_count - old_sym_count} updates [" +
"#{data_ready_key} (#{date})]")
log.debug("A")
STDOUT.flush
        check(update_symbol_count > old_sym_count)
#!!!!Note: data_ready_key can be published before all of <self>'s updates
#!!!!  have been completed - The subscriber needs to be aware of that!!!!
        publish data_ready_key
      else
log.debug("#{__method__}: no updates this time - #{data_ready_key} (#{date})")
log.debug("[#{self}] #{msg}")
log.debug("B")
STDOUT.flush
        # Of course, don't publish if no updates occurred this time.
      end
    else
      date = DateTime.current
      if @update_retries > UPDATE_RETRY_LIMIT then
        msg = "EOD update NOT completed (for #{data_ready_key} [#{date}])" +
          " - time limit was reached."
      else
        msg = "EOD update has been completed for #{data_ready_key} (#{date})"
      end
log.debug("[#{self}] #{msg}")
log.info("C - trying to shut down")
STDOUT.flush
      log.info(msg)
#!!!!Do we need to publish a "eod-updates-finished" status?
      shutdown  # The job is complete.
    end
  rescue StandardError => e
#!!!Log/report/...
  end

  pre :has_symbols do ! target_symbols.nil? end
  def update_completed
    update_symbol_count == target_symbols.count
  end

  pre :update_not_complete do ! update_completed end
  pre :remaining_symbols_set do ! @remaining_symbols.nil? end
  post :update_count do
    update_symbol_count >= 0 && update_symbol_count <= target_symbols.count end
  def update_eod_data
    @update_error = false
    update_interrupted = true
    storage_manager.update_data_stores(@remaining_symbols, end_date)
    update_interrupted = false
    @remaining_symbols.each do |s|
#!!!!We may need (in pseudocode), instead:
#!!!!TO-DO:  !!!DO-THIS:!!!!
#!!!if storage_manager.includes_data_for_today(s) then
      if ! storage_manager.data_up_to_date_for(s, end_date) then
#!!!      if storage_manager.last_update_empty_for(s) then
        log.debug("(no data was retrieved for #{s})")
      else
        # Update for s was successful, so remove s from the "check-for-eod"
        # list and add it to the "eod-data-ready" list.
        remove_from_set(eod_check_key, s)
        add_set(data_ready_key, s, DEFAULT_EXPIRATION_SECONDS)
        @update_symbol_count += 1
        @remaining_symbols.delete(s)
        log.info("last update count: " +
                 "#{storage_manager.last_update_count_for(s)}")
      end
    end
  rescue StandardError => e
    log.warn(e + "[#{caller}]")
    if update_interrupted then
      @update_error = true
    end
  end

  private

  attr_reader :storage_manager, :log
  # The ending date to use for data retrieval
  attr_reader :end_date

  SECONDS_BETWEEN_UPDATE_TRIES, MAX_SECONDS_PER_UPDATE = 30, 20
  UPDATE_RETRY_LIMIT = 650

  pre :args_good do |target_syms, check_key, log|
    ! (target_syms.nil? || check_key.nil? || log.nil?) end
  pre :syms_is_set do |tgt_syms| tgt_syms.is_a?(Set) && tgt_syms.count > 0 end
  post :attrs_set do eod_check_key != nil && target_symbols != nil end
  post :has_symbols do ! target_symbols.empty? end
  post :remaining_symbols do @remaining_symbols == target_symbols end
  post :good_ready_key do data_ready_key != nil && ! data_ready_key.empty? end
  post :stor_mgr_set do storage_manager != nil end
  post :log_set do log != nil end
  post :invariant do invariant end
  def initialize(target_syms, eod_chkey, enddate, the_log)
    @log = the_log
    data_config = DataConfig.new(log)
    @data_ready_key = new_eod_data_ready_key
    @eod_check_key = eod_chkey
    @end_date = enddate
    @target_symbols = target_syms
    @remaining_symbols = target_symbols.clone
    @update_symbol_count = 0
    @storage_manager = data_config.data_storage_manager
    @update_retries = 0
    # Make 'Publication' module happy:
    @default_publishing_channel = EOD_DATA_CHANNEL
    super(run_now: true, execution_interval: SECONDS_BETWEEN_UPDATE_TRIES,
          timeout_interval: MAX_SECONDS_PER_UPDATE) do |task|
      perform_update(task)
    end
log.debug("end of 'new' I am: #{self.inspect}")
  end

  # class invariant
  def invariant
    (
      ! storage_manager.nil? && ! log.nil? &&
      ! target_symbols.nil? && ! target_symbols.empty? &&
      ! data_ready_key.nil? && ! data_ready_key.empty? &&
      ! update_symbol_count.nil? && update_symbol_count >= 0 &&
      (@remaining_symbols.count ==
          target_symbols.count - update_symbol_count) &&
      ! eod_check_key.nil?
    )
  end

end

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Management of EOD data retrieval logic
# Subscribes to 'eod_check_channel' for "eod-check" notifications; obtains
# the current list of symbols to be checked and, for each symbol, s:
#   if the latest EOD data for s is ready:
#     retrieve the latest data for s
#     store the retrieved data in the correct location for s
# Publishes the list of symbols for which data has been retrieved and
# stored to the "eod-data-ready" channel.
#!!!old: class EODRetrievalManager < PublisherSubscriber
class EODRetrievalManager < Subscriber
  include Contracts::DSL, RedisFacilities, TatServicesFacilities

  public  ###  Access

  attr_reader :update_error, :eod_check_channel, :eod_data_ready_channel,
    :service_tag
  # List of symbols found to be "ready" upon 'eod_check_channel' notice:
  attr_reader :target_symbols

  public  ###  Basic operations

  def execute
    # (!!!At this point - and maybe always - this manager only responds to
    # termination orders!!!!)
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
                                     end_date, log)
      # Let the "data wrangler" do the actual data-retrieval work.
      wrangler.execute
    end
  end

  #!!!!!TO-DO: Figure out how to detect/handle an invalid symbol!!!!!
  post :attrs_set do ! (target_symbols.nil? || update_symbol_count.nil?) end
  post :published do update_error || (update_completed &&
      implies(target_symbols.count > 0, cardinality(data_ready_key) ==
              target_symbols.count))
  end
  def old_prethreading___wait_for_and_process_eod_event
    @target_symbols = nil
    @update_symbol_count = 0
    wait_for_eod_request
    # Iterate until all of `target_symbols' have had their EOD data updated.
    while ! update_completed
      if ! eod_check_key.nil? then
        update_eod_data
      else
        error_msg = "'wait_for_eod_request' failed to obtain symbol key"
        error(error_msg)
        raise error_msg
      end
      if ! update_completed then
        sleep RETRY_WAIT_SECONDS
      end
    end
    publish data_ready_key
  end

#!!!!TO-DO!!!! - remove update_completed:
  def update_completed
    target_symbols != nil && update_symbol_count == target_symbols.count
  end

  private

#!!!!TO-DO!!!! - remove update_completed:
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

#!!!!TO-DO!!!! - remove update_eod_data:
  pre :eod_check_key do eod_check_key != nil end
  pre :update_not_complete do ! update_completed end
  post :syms_ready do target_symbols != nil && target_symbols.count >= 0 end
  post :update_count do
    update_symbol_count >= 0 && update_symbol_count <= target_symbols.count end
  def update_eod_data
    @update_error = false
    update_interrupted = true
    storage_manager.update_data_stores(target_symbols)
    update_interrupted = false
    target_symbols.each do |s|
#!!!!We may need (in pseudocode), instead:
#!!!if storage_manager.includes_data_for_today(s) then
      if storage_manager.last_update_empty_for(s) then
        debug("(no data was retrieved for #{s})")
      else
        # Update for s was successful, so remove s from the "check-for-eod"
        # list and add it to the "eod-data-ready" list.
        remove_from_set(eod_check_key, s)
        add_set(data_ready_key, s, DEFAULT_EXPIRATION_SECONDS)
        @update_symbol_count += 1
        info("last update count: " +
                 "#{storage_manager.last_update_count_for(s)}")
      end
    end
  rescue StandardError => e
    warn(e + "[#{caller}]")
    if update_interrupted then
      @update_error = true
    end
  end

  private  ### Hook method implementations

  # Finish up for 'wait_for_eod_request'.
  post :target_syms do target_symbols != nil && target_symbols.is_a?(Set) end
  def post_process_subscription(channel)
    @target_symbols = Set.new(retrieved_set(eod_check_key))
  end

  private

#!!!!to-do: Get rid of data_ready_key, storage_manager!!!:
  attr_reader :storage_manager, :eod_check_key, :data_ready_key, :log

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
@log.debug("#{self.class} - PID: #{$$}")
@storage_manager = data_config.data_storage_manager #!!!!!!!!!
    @update_error = false
@data_ready_key = new_eod_data_ready_key  #!!!!<-kill me
    @run_state = SERVICE_RUNNING
    @service_tag = EOD_DATA_RETRIEVAL
    init_redis_clients
    super(EOD_CHECK_CHANNEL)  # i.e., subscribe channel
#super(EOD_DATA_CHANNEL, EOD_CHECK_CHANNEL)
#!!!!!! Note: 'create_status_report_timer' is not used here due to not being
#!!!!!! compatible with the subscription mechanism.
    # Create an alternate Redis for the timer to avoid conflict with
    # Redis subscriptions.
    create_status_report_timer
    @status_task.execute
  end

end
