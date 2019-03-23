require 'set'
require 'ruby_contracts'
require 'data_config'
require 'publication'
require 'tat_util'
require 'tat_services_facilities'
require 'concurrent-ruby'

# Objects responsible for, once an eod-check-symbols signal has been
# received (i.e., it's time to check if data is ready for the "target
# symbols"), managing the polling of the data provider and, when data is
# found to be available, updating the application's data store with the new
# EOD data
# Note: This class is NO LONGER a TimerTask - so !!!!!fixme!!!!.  The updating work is triggered by
# calling 'execute', which causes the 'perform_update' method to be invoked
# periodically (every SECONDS_BETWEEN_UPDATE_TRIES seconds).
# 'perform_update' will continue to do the polling and updating work (i.e.,
# retrieving the latest available data for each tradable identified by
# 'target_symbols' and storing it) each time it is called until all needed
# data has been retrieved/updated, at which point the thread (TimerTask)
# shuts itself down.
class EODDataWrangler
  include Contracts::DSL, Publication, TatServicesFacilities, TatUtil

  public

  attr_reader :data_ready_key, :eod_check_key
  # Original list of symbols (tradables) targeted for retrieval:
  attr_reader :target_symbols
  # Remaining symbols (tradables) targeted not yet retrieved:
  attr_reader :remaining_symbols
  attr_reader :update_error

  public  ###  Basic operations

  def execute
    @timer.execute
  end

##########################!!!????????????????????!!!!!!!!!!!!!!!!!!
  protected

  # Notify me/self (child thread/data-wrangler).
  def notify_from_thread(time, result, exception)
    msg = "(#{time}) wrangler (me) thread update: "
    if result.nil? then
      msg += "error: '#{exception}' (#{exception.class})"
      log.warn(msg)
    else
      msg += "result: '#{result.inspect}'"
      log.info(msg)
    end
  end

  alias_method :update, :notify_from_thread
##########################!!!????????????????????!!!!!!!!!!!!!!!!!!

  private

def send_eod_retrieval_completed(key)
log.debug("'#{__method__}' key: #{key}")
log.debug("'#{__method__}' - I belong in some other class/module!!!!")
end

  pre  :symbols_remain do ! remaining_symbols.empty? end
  pre  :invariant do invariant end
  post :invariant do invariant end
  def perform_update(task)
log.debug("#{self}.#{__method__} starting")
$stdout.flush
raise "This not be your foot"
    check(! remaining_symbols.empty?)
    if @update_retries > UPDATE_RETRY_LIMIT then
system("echo '#{__method__} expired: shutting down...' >>/tmp/edw#{$$}")
      date = DateTime.current
      msg = "EOD update NOT completed (for #{data_ready_key} [#{date}])" +
        " - time limit was reached."
log.debug("#{self}.#{__method__} expired - shutting down...")
      log.warn(msg)
$stdout.flush
      shutdown
    else
      check(remaining_symbols.count > 0)
      @update_retries += 1
      old_remaining_count = remaining_symbols.count
log.debug("#{self}.#{__method__} calling 'update_eod_data'")
      update_eod_data
      if remaining_symbols.count < old_remaining_count then
#!!!!Note: data_ready_key can be published before all of <self>'s updates
#!!!!  have been completed - The subscriber needs to be aware of that!!!!
        # At least one tradable/symbol retrieval was completed:
        publish data_ready_key
log.debug("#{self}.#{__method__} published #{data_ready_key}")
        if remaining_symbols.empty? then
system("echo '#{__method__} finished: shutting down...' >>/tmp/edw#{$$}")
log.debug("#{self}.#{__method__} finished - shutting down...")
#!!!!Do we need to publish a "eod-updates-finished" status? [probably]:
          send_eod_retrieval_completed(data_ready_key)
          # The requested retrievals have been completed.
          shutdown
        end
      end
    end
log.debug("#{self}.#{__method__} ending")
  rescue StandardError => e
#!!!Log/report/...
  end

  pre :update_not_complete do ! remaining_symbols.empty? end
  def update_eod_data
    @update_error = false
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
  rescue StandardError => e
    msg = e + "[#{caller}]"
    if update_interrupted then
      @update_error = true
    end
    log.warn(msg)
  rescue Exception => e
  end

  private

  attr_reader :storage_manager, :log
  # The ending date to use for data retrieval
  attr_reader :end_date

  SECONDS_BETWEEN_UPDATE_TRIES, MAX_SECONDS_PER_UPDATE = 30, 20
  UPDATE_RETRY_LIMIT = 650
#!!!  UPDATE_RETRY_LIMIT = 6

  pre :args_good do |target_syms, check_key, log|
    ! (target_syms.nil? || check_key.nil? || log.nil?) end
  pre :syms_is_set do |tgt_syms| tgt_syms.is_a?(Set) && tgt_syms.count > 0 end
  post :attrs_set do eod_check_key != nil && target_symbols != nil end
  post :has_symbols do ! target_symbols.empty? end
  post :remaining_symbols do remaining_symbols == target_symbols end
  post :good_ready_key do data_ready_key != nil && ! data_ready_key.empty? end
  post :stor_mgr_set do storage_manager != nil end
  post :log_set do log != nil end
  post :no_retries_yet do @update_retries == 0 end
  post :invariant do invariant end
  def initialize(target_syms, eod_chkey, enddate, the_log)
    @log = the_log
    # Let the caller/creator perform some initialization on 'self'.
    yield self
    data_config = DataConfig.new(log)
    @data_ready_key = new_eod_data_ready_key
    @eod_check_key = eod_chkey
    @end_date = enddate
    @target_symbols = target_syms
    @remaining_symbols = target_symbols.clone
    @storage_manager = data_config.data_storage_manager
    @update_retries = 0
    # Make 'Publication' module happy:
    @default_publishing_channel = EOD_DATA_CHANNEL
    @timer = Concurrent::TimerTask.new(run_now: true,
              execution_interval: SECONDS_BETWEEN_UPDATE_TRIES,
              timeout_interval: MAX_SECONDS_PER_UPDATE) do |task|
      begin
        perform_update(task)
      rescue Exception => e
        puts "I caught myself an #{e}"
        raise e
      end
    end
    @timer.add_observer(self)
  end

  # class invariant
  def invariant
    (
      ! storage_manager.nil? && ! log.nil? &&
      ! target_symbols.nil? && ! target_symbols.empty? &&
      ! data_ready_key.nil? && ! data_ready_key.empty? &&
      ! eod_check_key.nil? && ! remaining_symbols.nil?
    )
  end

end


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
class FirstVersion___EODDataWrangler < Concurrent::TimerTask
  include Contracts::DSL, Publication, TatServicesFacilities, TatUtil

  public

  attr_reader :data_ready_key, :eod_check_key
  # Original list of symbols (tradables) targeted for retrieval:
  attr_reader :target_symbols
  # Remaining symbols (tradables) targeted not yet retrieved:
  attr_reader :remaining_symbols
  attr_reader :update_error

  private

def send_eod_retrieval_completed(key)
log.debug("'#{__method__}' key: #{key}")
log.debug("'#{__method__}' - I belong in some other class/module!!!!")
end

  pre  :symbols_remain do ! remaining_symbols.empty? end
  pre  :invariant do invariant end
  post :invariant do invariant end
  def perform_update(task)
log.debug("#{self}.#{__method__} starting")
$stdout.flush
check(false)
    check(! remaining_symbols.empty?)
    if @update_retries > UPDATE_RETRY_LIMIT then
system("echo '#{__method__} expired: shutting down...' >>/tmp/edw#{$$}")
      date = DateTime.current
      msg = "EOD update NOT completed (for #{data_ready_key} [#{date}])" +
        " - time limit was reached."
log.debug("#{self}.#{__method__} expired - shutting down...")
      log.warn(msg)
$stdout.flush
      shutdown
    else
      check(remaining_symbols.count > 0)
      @update_retries += 1
      old_remaining_count = remaining_symbols.count
log.debug("#{self}.#{__method__} calling 'update_eod_data'")
      update_eod_data
      if remaining_symbols.count < old_remaining_count then
#!!!!Note: data_ready_key can be published before all of <self>'s updates
#!!!!  have been completed - The subscriber needs to be aware of that!!!!
        # At least one tradable/symbol retrieval was completed:
        publish data_ready_key
log.debug("#{self}.#{__method__} published #{data_ready_key}")
        if remaining_symbols.empty? then
system("echo '#{__method__} finished: shutting down...' >>/tmp/edw#{$$}")
log.debug("#{self}.#{__method__} finished - shutting down...")
#!!!!Do we need to publish a "eod-updates-finished" status? [probably]:
          send_eod_retrieval_completed(data_ready_key)
          # The requested retrievals have been completed.
          shutdown
        end
      end
    end
log.debug("#{self}.#{__method__} ending")
  rescue StandardError => e
#!!!Log/report/...
  end

  pre :update_not_complete do ! remaining_symbols.empty? end
  def update_eod_data
    @update_error = false
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
  rescue StandardError => e
    msg = e + "[#{caller}]"
    if update_interrupted then
      @update_error = true
    end
    log.warn(msg)
  rescue Exception => e
  end

  private

  attr_reader :storage_manager, :log
  # The ending date to use for data retrieval
  attr_reader :end_date

  SECONDS_BETWEEN_UPDATE_TRIES, MAX_SECONDS_PER_UPDATE = 30, 20
  UPDATE_RETRY_LIMIT = 650
#!!!  UPDATE_RETRY_LIMIT = 6

  pre :args_good do |target_syms, check_key, log|
    ! (target_syms.nil? || check_key.nil? || log.nil?) end
  pre :syms_is_set do |tgt_syms| tgt_syms.is_a?(Set) && tgt_syms.count > 0 end
  post :attrs_set do eod_check_key != nil && target_symbols != nil end
  post :has_symbols do ! target_symbols.empty? end
  post :remaining_symbols do remaining_symbols == target_symbols end
  post :good_ready_key do data_ready_key != nil && ! data_ready_key.empty? end
  post :stor_mgr_set do storage_manager != nil end
  post :log_set do log != nil end
  post :no_retries_yet do @update_retries == 0 end
  post :invariant do invariant end
  def initialize(target_syms, eod_chkey, enddate, the_log)
    @log = the_log
    # Let the caller/creator perform some initialization on 'self'.
    yield self
    data_config = DataConfig.new(log)
    @data_ready_key = new_eod_data_ready_key
    @eod_check_key = eod_chkey
    @end_date = enddate
    @target_symbols = target_syms
    @remaining_symbols = target_symbols.clone
    @storage_manager = data_config.data_storage_manager
    @update_retries = 0
    # Make 'Publication' module happy:
    @default_publishing_channel = EOD_DATA_CHANNEL
    super(run_now: true, execution_interval: SECONDS_BETWEEN_UPDATE_TRIES,
          timeout_interval: MAX_SECONDS_PER_UPDATE) do |task|
      begin
        perform_update(task)
      rescue Exception => e
        puts "I caught myself an #{e}"
        raise e
      end
    end
  end

  # class invariant
  def invariant
    (
      ! storage_manager.nil? && ! log.nil? &&
      ! target_symbols.nil? && ! target_symbols.empty? &&
      ! data_ready_key.nil? && ! data_ready_key.empty? &&
      ! eod_check_key.nil? && ! remaining_symbols.nil?
    )
  end

end
