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

  attr_reader :eod_check_key, :data_ready_key, :terminated

  PROC_NAME = "EOD Retrieval"

  #####  State-changing operations

  # For each symbol, s, in the set of symbols associated with 'eod_check_key'
  # (i.e., queue_contents(eod_check_key)), poll the data provider for the
  # latest data for s and, when those data become available, retrieve and
  # store them.  When the data for all symbols in queue_contents(eod_check_key)
  # are up to date, remove eod_check_key from the messaging queue (i.e.,
  # call remove_from_eod_check_queue(eod_check_key) and then call 'exit 0' -
  # i.e., terminate the process normally.
  pre  :err_tag do |err_tag, retrytag| err_tag != nil && retrytag != nil end
  pre  :at_least_1_tradable do queue_count(eod_check_key) > 0 end
  pre  :check_key_in_queue  do eod_check_queue_contains(eod_check_key) end
  post :key_remains_iff_terminated   do
    terminated == eod_check_queue_contains(eod_check_key) end
  post :tags_set do |result, err_tag, retrytag|
    @error_msg_key == err_tag && @retry_tag == retrytag end
  def execute(err_tag, retrytag)
    @error_msg_key = err_tag
    @retry_tag = retrytag
    @update_retries = 0
    @storage_manager = owner.config.data_storage_manager
    loop do
      @terminated = termination_ordered(eod_check_key, true)
      if terminated then
        break
      end
      perform_update
      @update_retries += 1
      if updates_completed || update_retries == UPDATE_RETRY_LIMIT then
        break
      end
      sleep SECONDS_BETWEEN_UPDATE_TRIES
    end
    remaining_symbols = queue_contents(eod_check_key)
    if terminated then
      msg = "Termination ordered for process #{$$} " +
        "(#{self.class}:#{__method__})"
      error_log.info(msg)
puts msg  #!!!![tmp/debugging]
      # (Since 'terminated' implies that the data-retrieval has not
      # completed, the queue is left intact ['remove_from_eod_check_queue' is
      # not called] so that a future process will be able to obtain the key
      # in order to complete the retrieval.)
    else
      if ! updates_completed then
        # Limit has been reached:
        check(! terminated && update_retries == UPDATE_RETRY_LIMIT,
              'update_retries == limit')
        msg = "#{PROC_NAME}: Time limit reached - failed to bring the " +
          "following symbols up to date:\n" + remaining_symbols.join(",")
        error_log.warn(msg)
        check(remaining_symbols.count > 0, 'updates not completed')
        send_eod_retrieval_timed_out(data_ready_key, msg)
      else
        check(remaining_symbols.count == 0, 'updates completed')
        send_eod_retrieval_completed(data_ready_key)
        error_log.info("process #{$$}: EOD retrieval completed.")
      end
      # Clean up (not 'terminated'). (!!!reusable/refactorable logic!!!?):
      remove_from_eod_check_queue(eod_check_key)
    end
    # The requested retrievals have been completed or timed-out - the child
    # can exit.
    exit 0
  end

  #####  Boolean queries

  # Have all tradables assigned to this object been updated and their
  # symbol removed from the 'eod_check_key' queue?
  def updates_completed
    result = queue_count(eod_check_key) == 0
    result
  end

  #####  Post-'initialize' configuration
  attr_accessor :error_log, :config
  attr_writer   :log

  # Set self's 'log', 'error_log', and 'config' attributes.
  pre  :good_hash do |hash| hash != nil && hash.count >= 3 end
  pre  :good_args do |hash|
    ! (hash[:log].nil? || hash[:elog].nil? || hash[:config].nil?) end
  post :configured do |r, hash| self.log == hash[:log] &&
    self.error_log == hash[:elog] && self.config == hash[:config] end
  def configure(log:, elog:, config:)
    self.log = log
    self.error_log = elog
    self.config = config
  end

  private   ##### Implementation

  pre  :within_retry_limit do update_retries < UPDATE_RETRY_LIMIT end
  pre  :storage_mgr_set do ! storage_manager.nil? end
  pre  :invariant do invariant end
  post :invariant do invariant end
  def perform_update
    old_count = queue_count(eod_check_key)
    update_eod_data
    # If at least one symbol was updated and removed from the queue:
    if queue_count(eod_check_key) < old_count then
      # (Note: data_ready_key can be published before all of <self>'s updates
      # have been completed - The subscriber needs to be aware of that.)
      # At least one tradable/symbol retrieval was completed:
      publish data_ready_key
      if next_eod_ready_key != data_ready_key then
        # Insurance, in case subscriber crashes while processing data_ready_key:
        enqueue_eod_ready_key data_ready_key
      end
    end
  rescue StandardError => e
    msg = "#{self.class}.#{__method__} caught #{e}"
    error_log.debug(msg)
    send_generic_message(@error_msg_key, msg)   # (no retry)
    exit 1
  end

  pre :storage_mgr_set do ! storage_manager.nil? end
  pre :not_finished do ! updates_completed end
  def update_eod_data
    update_interrupted = true
    storage_manager.update_data_stores(symbols: queue_contents(eod_check_key))
    update_interrupted = false
    # Iterate over each member of the 'eod_check_key' queue.
    (1 .. queue_count(eod_check_key)).each do
      head = queue_head(eod_check_key)
      check(head == queue_contents(eod_check_key).first, 'head is first')
      if ! storage_manager.data_up_to_date_for(head, end_date) then
        error_log.debug("(data not yet up to date for #{head})")
        # (Move the head of the 'eod_check_key' queue to the tail.)
        rotate_queue(eod_check_key)
        # Comment out (for efficiency) after enough testing!!!!:
        check(queue_tail(eod_check_key) == head, 'qtail == head')
      else
        error_log.debug("(data UP TO DATE for #{head})")
        # Update for 'head' was successful, so remove 'head' from the
        # "check-for-eod" queue and add it to the "eod-data-ready" queue.
        move_head_to_tail(eod_check_key, data_ready_key)
        # Remove/comment these (for efficiency) after enough testing!!!!:
        check(! queue_contents(eod_check_key).include?(head), 'head moved')
        check(queue_tail(data_ready_key) == head, 'to new tail')
      end
      check(queue_count(eod_check_key) == 1 ||
            queue_head(eod_check_key) != head, 'queue_head(eckey) != head')
    end
  rescue SocketError => e
    msg = "Error contacting data provider: #{e}"
    send_generic_message(@error_msg_key, "#{@retry_tag}:#{msg}")
    # Indicate to parent process that the operation should be retried.
    exit 2
  rescue StandardError => e
    msg = "#{e} [#{caller}]"
    if update_interrupted then
      send_generic_message(@error_msg_key, msg)   # (no retry)
      exit 3
    end
  rescue Exception => e
    error_log.debug("#{self}.#{__method__} caught #{e}")
    send_generic_message(@error_msg_key, msg)   # (no retry)
    exit 4
  end

  private

  attr_reader   :storage_manager, :update_retries, :owner
  # The ending date to use for data retrieval
  attr_reader :end_date

  SECONDS_BETWEEN_UPDATE_TRIES, MAX_SECONDS_PER_UPDATE = 30, 20
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
    @data_ready_key = new_eod_data_ready_key
    @eod_check_key = eod_chkey
    @end_date = enddate
    @update_retries = 0
    # Make 'Publication' module happy:
    @default_publishing_channel = EOD_DATA_CHANNEL
    initialize_message_brokers(owner.config)
    initialize_pubsub_broker(owner.config)
puts "#{self.class} inited - guts: #{self.inspect}"
  end

  # class invariant
  def invariant
    (
      ! log.nil? && ! data_ready_key.nil? && ! data_ready_key.empty? &&
      ! eod_check_key.nil?
    )
  end

end
