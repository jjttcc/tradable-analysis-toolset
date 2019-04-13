require 'tiingo_data_retriever'
require 'file_tradable_storage'

class DataConfig
  include Contracts::DSL

  public  ###  Constants

  # Number of seconds until the next "tradable-tracking cleanup" needs to
  # be performed:
  #TRACKING_CLEANUP_INTERVAL = 61200
  TRACKING_CLEANUP_INTERVAL = 17200 #!!!!test!!!!

  # redis application and administration ports
  REDIS_APP_PORT, REDIS_ADMIN_PORT = 16379, 26379

  public

  # New instance of the EOD data-retrieval object
  def data_retriever
    TiingoDataRetriever.new(data_retrieval_token, log)
  end

  # New instance of the object responsible for storing retrieved data to
  # persistent store
  def data_storage_manager
    FileTradableStorage.new(mas_data_path, data_retriever, log)
  end

  def redis_application_client
    Redis.new(port: REDIS_APP_PORT)
  end

  def redis_administration_client
    Redis.new(port: REDIS_ADMIN_PORT)
  end

  # Is debug-logging enabled?
  def debugging?
    ENV.has_key?(DEBUG_ENV_VAR)
  end

  private

  EOD_ENV_VAR = 'TIINGO_TOKEN'
  DATA_PATH_ENV_VAR = 'MAS_RUNDIR'
  DEBUG_ENV_VAR = 'TAT_DEBUG'

  attr_reader :log

  def data_retrieval_token
    result = ENV[EOD_ENV_VAR]
    if result.nil? || result.empty? then
      raise "EOD data token environment variable #{EOD_ENV_VAR} not set."
    end
    result
  end

  def mas_data_path
    result = ENV[DATA_PATH_ENV_VAR]
    if result.nil? || result.empty? then
      raise "data path environment variable #{DATA_PATH_ENV_VAR} not set."
    end
    result
  end

  private  ###  Initialization

  def initialize(the_log)
    if the_log.nil? then
      raise "#{self.class}.new: invalid argument - 'the_log' is nil"
    end
    @log = the_log
  end

end
