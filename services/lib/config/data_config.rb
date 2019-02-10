
class DataConfig
  include Contracts::DSL

  public

  # EOD data-retrieval object
  def data_retriever
    TiingoDataRetriever.new(data_retrieval_token, log)
  end

  # object responsible for storing retrieved data to persistent store
  def data_storage_manager
    FileTradableStorage.new(mas_data_path, data_retriever, log)
  end

  # redis channel for "check for eod data" notifications
  def eod_check_channel
    EOD_CHECK_CHANNEL
  end

  # redis channel for eod-data-ready notifications
  def eod_data_ready_channel
    EOD_CHECK_CHANNEL
  end

  # new key for symbol set associated with "check for eod data" notifications
  def new_eod_check_key
    EOD_CHECK_KEY_BASE + rand(1..9999999999).to_s
  end

  # new key for symbol set associated with eod-data-ready notifications
  def new_eod_data_ready_key
    EOD_DATA_KEY_BASE + rand(1..9999999999).to_s
  end

  private

  EOD_ENV_VAR = 'TIINGO_TOKEN'
  DATA_PATH_ENV_VAR = 'MAS_RUNDIR'
  if ENV.has_key?('RAILS_ENV') && ENV['RAILS_ENV'] == 'test' then
    # This is a test.  This is only a test...
    # https://www.youtube.com/watch?v=eic8hJu0sQ8
    EOD_CHECK_CHANNEL = 'eod-checktime-test'
    EOD_DATA_CHANNEL = 'eod-data-ready-test'
    EOD_CHECK_KEY_BASE = 'eod-check-symbols-test'
    EOD_DATA_KEY_BASE = 'eod-ready-symbols-test'
  else
    EOD_CHECK_CHANNEL = 'eod-checktime'
    EOD_DATA_CHANNEL = 'eod-data-ready'
    EOD_CHECK_KEY_BASE = 'eod-check-symbols'
    EOD_DATA_KEY_BASE = 'eod-ready-symbols'
  end

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
