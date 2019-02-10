require 'redis'
require 'ruby_contracts'
require 'data_config'
require 'error_log'
require 'tiingo_data_retriever'
require 'file_tradable_storage'


# Management of EOD data retrieval logic
# Subscribes to 'eod_check_channel' for "eod-check" notifications; obtains
# the current list of symbols to be checked and, for each symbol, s:
#   if the latest EOD data for s is ready:
#     retrieve the latest data for s
#     store the retrieved data in the correct location for s
# Publishes the list of symbols for which data has been retrieved and
# stored to the "eod-data-ready" channel.
class EODRetrievalManager
  include Contracts::DSL

  public

  attr_reader :update_error, :update_symbol_count, :eod_check_channel,
    :eod_data_ready_channel
  # List of symbols found to be "ready" upon 'eod_check_channel' notice:
  attr_reader :target_symbols

  public

  #!!!!!TO-DO: Implement timeout or loop-count limit!!!!
  #!!!!!TO-DO: Figure out how to detect/handle an invalid symbol!!!!!
  post :attrs_set do ! (target_symbols.nil? || update_symbol_count.nil?) end
  post :published do update_error || (update_completed &&
      implies(target_symbols.count > 0, redis.scard(data_ready_key) ==
              target_symbols.count))
  end
  def execute
    wait_for_eod_request
    @update_symbol_count = 0
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
    redis.publish eod_data_ready_channel, data_ready_key
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
    redis.subscribe(eod_check_channel) do |on|
      on.message do |channel, symkey|
        @eod_check_key = symkey
        redis.unsubscribe channel
      end
    end
    @target_symbols = redis.smembers eod_check_key
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
        redis.srem(eod_check_key, s)
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

  private

  attr_reader :storage_manager, :eod_check_key, :redis, :log, :data_ready_key

  RETRY_WAIT_SECONDS = 50

  post :attrs_set do
    ! (eod_check_channel.nil? || storage_manager.nil? ||
       redis.nil? || log.nil?) end
  def initialize
    @log = ErrorLog.new
    data_config = DataConfig.new(log)
    @storage_manager = data_config.data_storage_manager
    @eod_check_channel = data_config.eod_check_channel
    @eod_data_ready_channel = data_config.eod_data_ready_channel
    @redis = Redis.new
    @update_error = false
    @update_symbol_count = 0
    @data_ready_key = data_config.new_eod_data_ready_key
  end

end
