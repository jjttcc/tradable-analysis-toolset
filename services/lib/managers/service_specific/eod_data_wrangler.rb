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
  # Original list of symbols (tradables) targeted for retrieval:
  attr_reader :target_symbols
  # Remaining symbols (tradables) targeted not yet retrieved:
  attr_reader :remaining_symbols

  PROC_NAME = "EOD Retrieval"

  public  ###  Basic operations

  pre :tag do |tag, rtag| tag != nil && rtag != nil end
  def execute(tag, rtag)
    @error_msg_key = tag
    @retry_tag = rtag
    @update_retries = 0
    data_config = DataConfig.new(log)
    @storage_manager = data_config.data_storage_manager
    while ! remaining_symbols.empty? && update_retries < UPDATE_RETRY_LIMIT
      perform_update
      sleep SECONDS_BETWEEN_UPDATE_TRIES
      @update_retries += 1
    end
    if ! remaining_symbols.empty? then
      # Limit has been reached:
      check(update_retries == UPDATE_RETRY_LIMIT)
      msg = "#{PROC_NAME}: Time limit reached - failed to bring the " +
        "following symbols up to date:\n" +
        remaining_symbols.join(",")
      log.warn(msg)
    end
  end

  public  ###  Status report

  private

def send_eod_retrieval_completed(key)
log.debug("'#{__method__}' key: #{key}")
log.debug("'#{__method__}' - Finish me!!!!")
end

  pre  :symbols_remain do ! remaining_symbols.empty? end
  pre  :within_retry_limit do update_retries < UPDATE_RETRY_LIMIT end
  pre  :storage_mgr_set do ! storage_manager.nil? end
  pre  :invariant do invariant end
  post :invariant do invariant end
  def perform_update
log.debug("#{self}.#{__method__} starting")
    check(remaining_symbols.count > 0)
    old_remaining_count = remaining_symbols.count
    update_eod_data
    if remaining_symbols.count < old_remaining_count then
#!!!!Note: data_ready_key can be published before all of <self>'s updates
#!!!!  have been completed - The subscriber needs to be aware of that!!!!
      # At least one tradable/symbol retrieval was completed:
log.debug("#{__method__} (publishing #{data_ready_key})")
      publish data_ready_key
log.debug("#{__method__} (publishED #{data_ready_key})")
      if remaining_symbols.empty? then
        send_eod_retrieval_completed(data_ready_key)
        # The requested retrievals have been completed; child can exit.
        exit 0
      end
    end
  rescue StandardError => e
    log.debug("#{self}.#{__method__} caught #{e}")
#!!!what else???!!!!
  end

  pre :update_not_complete do ! remaining_symbols.empty? end
  pre :storage_mgr_set do ! storage_manager.nil? end
  def update_eod_data
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
  pre  :o_has_symbols do |o| ! o.target_symbols.empty? end
  post :attrs_set do eod_check_key != nil && target_symbols != nil end
  post :has_symbols do ! target_symbols.empty? end
  post :remaining_symbols do remaining_symbols == target_symbols end
  post :good_ready_key do data_ready_key != nil && ! data_ready_key.empty? end
  post :log_set do log != nil end
  post :no_retries_yet do update_retries == 0 end
  post :redis_init do ! (@redis.nil? || @redis_admin.nil?) end
  post :invariant do invariant end
  def initialize(owner, eod_chkey, enddate)
    @log = owner.log
    @data_ready_key = new_eod_data_ready_key
    @eod_check_key = owner.eod_check_key
    @end_date = enddate
    @target_symbols = owner.target_symbols
    @remaining_symbols = target_symbols.clone
log.debug("#{self.class}.new - tgtsyms: #{@target_symbols.inspect}")
    @update_retries = 0
    # Make 'Publication' module happy:
    @default_publishing_channel = EOD_DATA_CHANNEL
    init_redis_clients
  end

  # class invariant
  def invariant
    (
      ! log.nil? && ! target_symbols.nil? && ! target_symbols.empty? &&
      ! data_ready_key.nil? && ! data_ready_key.empty? &&
      ! eod_check_key.nil? && ! remaining_symbols.nil?
    )
  end

end
