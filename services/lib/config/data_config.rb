require 'tiingo_data_retriever'
require 'file_tradable_storage'

class DataConfig
  include Contracts::DSL

  public  ###  Constants

  # Number of seconds until the next "tradable-tracking cleanup" needs to
  # be performed:
  #TRACKING_CLEANUP_INTERVAL = 61200
  TRACKING_CLEANUP_INTERVAL = 17200 #!!!!test!!!!

  public

  # EOD data-retrieval object
  def data_retriever
    TiingoDataRetriever.new(data_retrieval_token, log)
  end

  # object responsible for storing retrieved data to persistent store
  def data_storage_manager
    FileTradableStorage.new(mas_data_path, data_retriever, log)
  end

  private

  EOD_ENV_VAR = 'TIINGO_TOKEN'
  DATA_PATH_ENV_VAR = 'MAS_RUNDIR'

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

  pre :log_exists do |log| ! log.nil? end
  def initialize(the_log)
    @log = the_log
  end

end
