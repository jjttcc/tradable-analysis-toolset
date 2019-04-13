require 'set'
require 'ruby_contracts'
require 'data_config'
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

  attr_reader :data_ready_key, :eod_check_key, :log

  PROC_NAME = "EOD Retrieval"

  public  ###  Basic operations

  pre :tag do |tag, rtag| tag != nil && rtag != nil end
  pre :at_least_1_tradable do queue_count(eod_check_key) > 0 end
  def execute(tag, rtag)
    @error_msg_key = tag
    @retry_tag = rtag
    @update_retries = 0
    data_config = DataConfig.new(log)
    @storage_manager = data_config.data_storage_manager
    loop do
      perform_update
      @update_retries += 1
      if updates_completed || update_retries == UPDATE_RETRY_LIMIT then
        break
      end
      sleep SECONDS_BETWEEN_UPDATE_TRIES
    end
    if ! updates_completed then
      # Limit has been reached:
      check(update_retries == UPDATE_RETRY_LIMIT, 'update_retries == limit')
#!!!!!Fix: replace 'therightkey' with the right name!!!!:
      remsyms = queue_contents(therightkey)
      msg = "#{PROC_NAME}: Time limit reached - failed to bring the " +
        "following symbols up to date:\n" + remsyms.join(",")
      log.warn(msg)
      send_eod_retrieval_timed_out(data_ready_key, msg)
    else
      send_eod_retrieval_completed(data_ready_key)
    end
    # The requested retrievals have been completed or timed-out - the child
    # can exit.
    exit 0
  end

  public  ###  Status report

  # Have all tradables assigned to this object been updated and their
  # symbol removed from the 'eod_check_key' queue?
  def updates_completed
    result = queue_count(eod_check_key) == 0
    result
  end

  private

  pre  :within_retry_limit do update_retries < UPDATE_RETRY_LIMIT end
  pre  :storage_mgr_set do ! storage_manager.nil? end
  pre  :invariant do invariant end
  post :invariant do invariant end
  def perform_update
    old_count = queue_count(eod_check_key)
log.debug("#{self}.#{__method__} starting")
    update_eod_data
    # If at least one symbol was updated and removed from the queue:
    if queue_count(eod_check_key) < old_count then
#!!!!Note: data_ready_key can be published before all of <self>'s updates
#!!!!  have been completed - The subscriber needs to be aware of that!!!!
      # At least one tradable/symbol retrieval was completed:
log.debug("#{__method__} (publishing #{data_ready_key})")
      publish data_ready_key
      add_eod_ready_key data_ready_key
log.debug("#{__method__} (publishED #{data_ready_key})")
    end
  rescue StandardError => e
    log.debug("#{self}.#{__method__} caught #{e}")
#!!!what else???!!!! - maybe: send_generic_message(...) and exit???!!!
  end

  pre :storage_mgr_set do ! storage_manager.nil? end
  pre :not_finished do ! updates_completed end
  def update_eod_data
log.debug("[UED] START")
    update_interrupted = true
    storage_manager.update_data_stores(symbols: queue_contents(eod_check_key))
    update_interrupted = false
log.debug("[UED(1)] qcount: #{queue_count(eod_check_key)}")
    # Iterate over each member of the 'eod_check_key' queue.
    (1 .. queue_count(eod_check_key)).each do
      head = queue_head(eod_check_key)
log.debug("[UED] head: #{head}")
      check(head == queue_contents(eod_check_key).first, 'head is first')
      if ! storage_manager.data_up_to_date_for(head, end_date) then
        log.debug("(data not yet up to date for #{head})")
        # (Move the head of the 'eod_check_key' queue to the tail.)
        rotate_queue(eod_check_key)
log.debug("[UED(2)] qcount: #{queue_count(eod_check_key)}")
        # Comment out (for efficiency) after enough testing!!!!:
        check(queue_tail(eod_check_key) == head, 'qtail == head')
      else
log.debug("(data UP TO DATE for #{head})")
        # Update for 'head' was successful, so remove 'head' from the
        # "check-for-eod" queue and add it to the "eod-data-ready" queue.
log.debug("[UED(3a)] [move_head_to_tail(#{eod_check_key}, #{data_ready_key})]")
        move_head_to_tail(eod_check_key, data_ready_key)
log.debug("[UED(3b)]")
log.debug("[UED(3c)] qcount: #{queue_count(eod_check_key)}")
        # Remove/comment these (for efficiency) after enough testing!!!!:
        check(! queue_contents(eod_check_key).include?(head), 'head moved')
        check(queue_tail(data_ready_key) == head, 'to new tail')
      end
log.debug("[UED(4)] qhead: #{queue_head(eod_check_key)}")
      check(queue_count(eod_check_key) == 1 ||
            queue_head(eod_check_key) != head, 'queue_head(eckey) != head')
    end
log.debug("[UED] END")
  rescue SocketError => e
    msg = "Error contacting data provider: #{e}"
log.debug("[UED] rescue1 - msg: #{msg}")
    send_generic_message(@error_msg_key, "#{@retry_tag}:#{msg}")
    # Indicate to parent process that the operation should be retried.
    exit 2
  rescue StandardError => e
    msg = "#{e} [#{caller}]"
log.debug("[UED] rescue2 - msg: #{msg}")
    if update_interrupted then
      send_generic_message(@error_msg_key, msg)   # (no retry)
      exit 3
    end
  rescue Exception => e
    log.debug("#{self}.#{__method__} caught #{e}")
#!!!!??:    send_generic_message(@error_msg_key, msg)   # (no retry)
    #!!!!Should we exit here???!!!!
    raise e
  end

  pre :storage_mgr_set do ! storage_manager.nil? end
  pre :not_finished do ! updates_completed end
  def update_eod_data_vsn2
    update_interrupted = true
    symbols = remaining_symbols
    storage_manager.update_data_stores(symbols: symbols)
    update_interrupted = false
    symbols.each do |s|
      check(queue_head(eod_check_key) == s)
      if ! storage_manager.data_up_to_date_for(s, end_date) then
        log.debug("(data not yet up to date for #{s})")
        # (Move the head [s] of the 'eod_check_key' queue to the tail.)
        move_head_to_tail(eod_check_key, eod_check_key)
        # Comment out (for efficiency) after enough testing!!!!:
        check(queue_tail(eod_check_key) == s)
      else
        # Update for s was successful, so remove s from the "check-for-eod"
        # queue and add it to the "eod-data-ready" queue.
        # (s is currently at the head of the 'eod_check_key' queue.)
        move_head_to_tail(eod_check_key, data_ready_key)
        # Remove this (for efficiency) after enough testing!!!!:
        check(! remaining_symbols.include?(s))
      end
      check(queue_head(eod_check_key) != s)
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
    log.debug("#{self}.#{__method__} caught #{e}")
#!!!!??:    send_generic_message(@error_msg_key, msg)   # (no retry)
    #!!!!Should we exit here???!!!!
    raise e
  end

  pre :check_key do ! eod_check_key.nil? && ! eod_check_key.empty? end
#!!!!OBSOLETE - remove soon:
  def remaining_symbols
    queue_contents(eod_check_key)
  end

  pre :update_not_complete do ! remaining_symbols.empty? end
  pre :storage_mgr_set do ! storage_manager.nil? end
  def old___remove____update_eod_data
    update_interrupted = true
    storage_manager.update_data_stores(symbols: remaining_symbols)
    update_interrupted = false
    symbols = remaining_symbols.clone
    symbols.each do |s|
      if ! storage_manager.data_up_to_date_for(s, end_date) then
        log.debug("(data not yet up to date for #{s})")
      else
        # Update for s was successful, so remove s from the "check-for-eod"
        # list and add it to the "eod-data-ready" list.
log.debug("ued - calling remove_from_set(#{eod_check_key}, #{s})")
        remove_from_set(eod_check_key, s)
log.debug("ued - calling add_set(#{data_ready_key}, #{s}, " +
"#{DEFAULT_EXPIRATION_SECONDS})")
        add_set(data_ready_key, s, DEFAULT_EXPIRATION_SECONDS)
log.debug("ued - survived call to add_set - removing #{s} from @remsym")
        remaining_symbols.delete(s)
        check(! remaining_symbols.include?(s))
      end
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
    log.debug("#{self}.#{__method__} caught #{e}")
#!!!!??:    send_generic_message(@error_msg_key, msg)   # (no retry)
    #!!!!Should we exit here???!!!!
    raise e
  end

  private

  attr_reader :storage_manager, :update_retries
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
  post :redis_init do ! (@redis.nil? || @redis_admin.nil?) end
  post :invariant do invariant end
  def initialize(owner, eod_chkey, enddate)
    @log = owner.log
    @data_ready_key = new_eod_data_ready_key
    @eod_check_key = eod_chkey
    @end_date = enddate
    @update_retries = 0
    # Make 'Publication' module happy:
    @default_publishing_channel = EOD_DATA_CHANNEL
    init_redis_clients
  end

  # class invariant
  def invariant
    (
      ! log.nil? && ! data_ready_key.nil? && ! data_ready_key.empty? &&
      ! eod_check_key.nil?
    )
  end

end
