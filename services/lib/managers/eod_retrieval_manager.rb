require 'redis'
require 'ruby_contracts'
require 'data_config'
require 'error_log'
require 'tiingo_data_retriever'
require 'file_tradable_storage'
require 'publisher_subscriber'
require 'tat_services_facilities'


# Management of EOD data retrieval logic
# Subscribes to 'eod_check_channel' for "eod-check" notifications; obtains
# the current list of symbols to be checked and, for each symbol, s:
#   if the latest EOD data for s is ready:
#     retrieve the latest data for s
#     store the retrieved data in the correct location for s
# Publishes the list of symbols for which data has been retrieved and
# stored to the "eod-data-ready" channel.
class EODRetrievalManager < PublisherSubscriber
  include Contracts::DSL, TatServicesFacilities

  public  ###  Access

  attr_reader :update_error, :update_symbol_count, :eod_check_channel,
    :eod_data_ready_channel
  # List of symbols found to be "ready" upon 'eod_check_channel' notice:
  attr_reader :target_symbols

  public  ###  Basic operations

  #!!!!!TO-DO: Implement timeouts or loop-count limit:
  #!!!!!         - If we're not finished, but took > {n} minutes, publish
  #!!!!!           that a/(possibly: another) chunk of tradables/symbols
  #!!!!!           is ready to be analyzed.  Continue to do this until
  #!!!!!           we are out of symbols.
  #!!!!!         - If a maximum time limit has been reached, give up
  #!!!!!           processing the remaining symbols and record the problem
  #!!!!!           somewhere.
  #!!!!!TO-DO: Figure out how to detect/handle an invalid symbol!!!!!
  post :attrs_set do ! (target_symbols.nil? || update_symbol_count.nil?) end
  post :published do update_error || (update_completed &&
      implies(target_symbols.count > 0, redis.scard(data_ready_key) ==
              target_symbols.count))
  end
  def execute
    wait_for_eod_request
    @update_symbol_count = 0
    # Iterate until all of `target_symbols' have had their EOD data updated.
    while ! update_completed do
      if ! eod_check_key.nil? then
        update_eod_data
      else
        error_msg = "'wait_for_eod_request' failed to obtain symbol key"
        log.error(error_msg)
        raise error_msg
      end
      if ! update_completed then
        sleep RETRY_WAIT_SECONDS
      end
    end
#!!!!We are probably going to move this to within the above loop and add
#!!!!logic to "publish..." whenever (if the data is slow in showing up)
#!!!!we have "gathered" enough tradables' data to publish a "chunk".
    publish data_ready_key
  end

  def update_completed
    target_symbols != nil && update_symbol_count == target_symbols.count
  end

  private

  pre  :update_not_completed do
    ! update_completed && update_symbol_count == 0 end
  post :update_not_completed do
    ! update_completed && update_symbol_count == 0 end
  post :target_symbols do ! target_symbols.nil? end
  post :key_set do eod_check_key != nil end
  def wait_for_eod_request
    subscribe_once do
      @eod_check_key = last_message
    end
  end

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
      if storage_manager.last_update_empty_for(s) then
        log.debug("(no data was retrieved for #{s})")
      else
        # Update for s was successful, so remove s from the "check-for-eod"
        # list and add it to the "eod-data-ready" list.
puts "(redis.srem(#{eod_check_key}, #{s}))"   #!!!!!!!!!!
        redis.srem(eod_check_key, s)
puts "(redis.sadd(#{data_ready_key}, #{s}))"  #!!!!!!!!!!
        redis.sadd(data_ready_key, s)
        @update_symbol_count += 1
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

  private  ### Hook method implementations

  # Finish up for 'wait_for_eod_request'.
  def post_process_subscription(channel)
    @target_symbols = redis.smembers eod_check_key
  end

  private

  attr_reader :storage_manager, :eod_check_key, :data_ready_key, :log

  RETRY_WAIT_SECONDS = 50

  post :attrs_set do ! (storage_manager.nil? || log.nil?) end
  def initialize
    @log = ErrorLog.new
    data_config = DataConfig.new(log)
    @storage_manager = data_config.data_storage_manager
    @update_error = false
    @update_symbol_count = 0
    @data_ready_key = new_eod_data_ready_key
    super(EOD_DATA_CHANNEL, EOD_CHECK_CHANNEL)
  end

end
