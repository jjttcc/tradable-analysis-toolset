require 'set'
require 'ruby_contracts'
require 'publication'
require 'tat_util'
require 'tat_services_facilities'

# Objects responsible for, once an eod-check-symbols signal has been
# received (i.e., it's time to check if data is ready for the "target
# symbols"), managing the polling of the data provider and, when data is
# found to be available, updating the application's data store with the new
# EOD data
# The updating work is triggered by calling 'execute', after having created
# an instance of this class.  Note: 'execute' is intended to be called from
# within a "fork"ed child process.
class EODDataWrangler
  include Contracts::DSL, Publication, TatServicesFacilities, TatUtil

  public

  #####  Access

  attr_reader   :eod_check_key, :data_ready_key, :terminated
  attr_accessor :intercomm

  PROC_NAME = "EOD Retrieval"

  #####  State-changing operations

  # For each symbol, s, in the set of symbols associated with 'eod_check_key'
  # (i.e., intercomm.eod_symbols(eod_check_key)), poll the data provider for
  # the latest data for s and, when those data become available, retrieve and
  # store them.  When the data for all symbols in
  # intercomm.eod_symbols(eod_check_key) are up to date, remove eod_check_key
  # from the messaging queue (via intercomm.remove_from_eod_check_queue) and
  # then call 'exit 0' - i.e., terminate the process normally.
  pre  :err_tag do |err_tag, retrytag| err_tag != nil && retrytag != nil end
  pre  :at_least_1_tradable do
    intercomm.eod_symbols_count(eod_check_key) > 0 end
  pre  :check_key_in_queue  do
    intercomm.eod_check_queue_contains(eod_check_key) end
  post :key_remains_iff_terminated   do
    terminated == intercomm.eod_check_queue_contains(eod_check_key) end
  post :tags_set do |result, err_tag, retrytag|
    @error_msg_key == err_tag && @retry_tag == retrytag end
  def execute(err_tag, retrytag)
    @error_msg_key, @retry_tag, @update_retries = err_tag, retrytag, 0
    @storage_manager = new_data_storage_manager
    test "#{__method__} calling update_data_store [stmgr: #{@storage_manager}]"
    update_data_store
    remaining_symbols = intercomm.eod_symbols(eod_check_key)
    test "#{__method__} - remaining_symbols: #{remaining_symbols}"
    if terminated then
      msg = "Termination ordered for process #{$$} " +
        "(#{self.class}:#{__method__})"
      warn(msg)
      # (Since 'terminated' implies that the data-retrieval has not
      # completed, the queue is left intact ['remove_from_eod_check_queue' is
      # not called] so that a future process will be able to obtain the key
      # in order to complete the retrieval.)
    else
      test "#{__method__} - cleaning up"
      perform_post_retrieval_cleanup(remaining_symbols)
      test "#{__method__} - FINISHED cleaning up"
    end
    # The requested retrievals have been completed or timed-out - the child
    # can exit.
    test "#{__method__} - EXITING"
    exit 0
  rescue SystemExit => e
    raise e   # (Don't intervene for an 'exit'.)
  rescue Exception => e
    msg = "#{self}.#{__method__} - Unexpected exception: #{e}"
    error(msg)
    # Notify the parent (EOD-retrieval service) process of the "issue":
    send_generic_message(@error_msg_key, msg)   # (no retry)
    exit 1
  end

  #####  Post-'initialize' configuration
  attr_accessor :error_log, :config
  attr_writer   :log

  # Set self's 'log', 'error_log', and 'config' attributes.
  pre  :good_hash do |hash| hash != nil && hash.count >= 3 end
  pre  :good_args do |hash|
    ! (hash[:log].nil? || hash[:elog].nil? || hash[:config].nil?) end
  post :configured do |r, hash| log == hash[:log] &&
    self.error_log == hash[:elog] && self.config == hash[:config] end
  def configure(log:, elog:, config:)
    self.log = log
    self.error_log = elog
    self.config = config
  end

  protected

  # Loop until all scheduled updates have been completed via
  # 'perform_update', or termination has been ordered, or the
  # UPDATE_RETRY_LIMIT has been reached.
  def update_data_store
    loop do
      @terminated = termination_ordered(eod_check_key, true)
      if terminated then
        debug "#{__method__} - termination has been ordered."
        break
      end
      perform_update
      @update_retries += 1
      debug "#{__method__} - ucmp, uretries&limit: " +
            "#{updates_completed}, #{update_retries}, #{UPDATE_RETRY_LIMIT}"
      if updates_completed || update_retries == UPDATE_RETRY_LIMIT then
        break
      end
      sleep @seconds_between_update_tries
    end
  end

  # Perform any needed cleanup after the data retrieval has completed or
  # been aborted.
  pre :not_dead do ! terminated end
  def perform_post_retrieval_cleanup(remaining_symbols)
    if ! updates_completed then
      # Limit has been reached:
      check(! terminated && update_retries == UPDATE_RETRY_LIMIT,
            'update_retries == limit')
      msg = "#{PROC_NAME}: Time limit reached - failed to bring the " +
        "following symbols up to date:\n" + remaining_symbols.join(",")
      warn(msg)
      check(remaining_symbols.count > 0, 'updates not completed')
      intercomm.notify_of_timeout(data_ready_key, msg)
      info("process #{$$}: EOD retrieval timed out (#{data_ready_key}).")
    else
      check(remaining_symbols.count == 0, 'updates completed')
      intercomm.notify_of_completion(data_ready_key)
      info("process #{$$}: EOD retrieval completed (#{data_ready_key}).")
    end
    # Clean up (not 'terminated').
    intercomm.remove_from_eod_check_queue(eod_check_key)
  end

  #####  Boolean queries

  # Have all tradables assigned to this object been updated and their
  # symbol removed from the 'eod_check_key' queue?
  def updates_completed
    result = intercomm.eod_symbols_count(eod_check_key) == 0
    test "#{__method__} - result, eod_check_key, stack: #{result}, "\
      "#{eod_check_key}\n#{caller.join("\n")}"
    result
  end

  private   ##### Implementation

  pre  :within_retry_limit do update_retries < UPDATE_RETRY_LIMIT end
  pre  :storage_mgr_set do ! storage_manager.nil? end
  pre  :invariant do invariant end
  post :invariant do invariant end
  def perform_update
    old_count = intercomm.eod_symbols_count(eod_check_key)
    debug "#{__method__} - old count: #{old_count}"
    update_eod_data
    # If at least one symbol was updated and removed from the queue:
    if intercomm.eod_symbols_count(eod_check_key) < old_count then
      # At least one tradable/symbol retrieval was completed:
      intercomm.notify_of_update(data_ready_key,
        intercomm.next_eod_ready_key != data_ready_key)
    end
    debug "#{__method__} - returning without apparent error."
  rescue StandardError => e
    msg = "#{self.class}.#{__method__} caught #{e}:\n#{e.backtrace.join("\n")}"
    error(msg)
    # Notify the parent (EOD-retrieval service) process of the "issue":
    send_generic_message(@error_msg_key, msg)   # (no retry)
    exit 1
  end

  pre :storage_mgr_set do ! storage_manager.nil? end
  pre :not_finished do ! updates_completed end
  def update_eod_data
    update_interrupted = true
    retrieve_and_store_data_for(intercomm.pending_symbols)
    update_interrupted = false
    intercomm.process_symbols_queue(data_ready_key) do |symbol|
      result = update_completed_for(symbol)
      adjective = (result)? "UP TO DATE": "not yet up to date"
      test "(data #{adjective} for #{symbol})"
      result
    end
  rescue SocketError => e
    msg = "Error contacting data provider: #{e}"
    # Notify the parent (EOD-retrieval service) process of the "issue":
    send_generic_message(@error_msg_key, "#{@retry_tag}:#{msg}")
    error(msg)
    # Indicate to parent process that the operation should be retried.
    exit 2
  rescue StandardError => e
    msg = "#{e} - backtrace:\n#{e.backtrace.join("\n")}"
    error(msg)
    if update_interrupted then
      # Notify the parent (EOD-retrieval service) process of the "issue":
      send_generic_message(@error_msg_key, msg)   # (no retry)
      exit 3
    end
  rescue Exception => e
    msg = "#{self}.#{__method__} caught #{e}"
    error(msg)
    # Notify the parent (EOD-retrieval service) process of the "issue":
    send_generic_message(@error_msg_key, msg)   # (no retry)
    exit 4
  end

  # Use 'storage_manager' to retrieve the latest data for 'symbols' and
  # store it in the configured persistent store.
  def retrieve_and_store_data_for(symbols)
    storage_manager.update_data_stores(symbols: symbols)
  end

  # Has the latest data for 'symbol' been retrieved and stored?
  def update_completed_for(symbol)
    storage_manager.data_up_to_date_for(symbol, end_date)
  end

  post :result_good do |result| result != nil end
  def new_data_storage_manager
    owner.config.data_storage_manager
  end

  private

  attr_reader   :storage_manager, :update_retries, :owner
  # The ending date to use for data retrieval
  attr_reader :end_date

  MAX_SECONDS_PER_UPDATE = 20
  UPDATE_RETRY_LIMIT = 650

  pre :args_good do |owner, check_key, enddate|
    ! (owner.nil? || check_key.nil? || enddate.nil?) end
  post :check_key_set do |r, o, ekey|
    eod_check_key != nil && eod_check_key == ekey end
  post :good_ready_key do data_ready_key != nil && ! data_ready_key.empty? end
  post :log_set do log != nil end
  post :no_retries_yet do update_retries == 0 end
  post :invariant do invariant end
  def initialize(owner, eod_chkey, enddate)
    @owner = owner
    @owner.configure_wrangler(self)
    @data_ready_key = intercomm.new_eod_data_ready_key
    @eod_check_key = eod_chkey
    @end_date = enddate
    @update_retries = 0
    @seconds_between_update_tries = configured_seconds_between_update_tries
    # Make 'Publication' module happy:
    @default_publishing_channel = intercomm.publication_channel
    initialize_message_brokers(owner.config)
    initialize_pubsub_broker(owner.config)
  end

  def configured_seconds_between_update_tries
    30
  end

  # class invariant
  def invariant
    (
      ! log.nil? && ! data_ready_key.nil? && ! data_ready_key.empty? &&
      ! eod_check_key.nil?
    )
  end

end
