require 'tiingo_data_retriever'
require 'file_tradable_storage'
require 'message_broker_configuration'

class DataConfig
  include Contracts::DSL

  public  ###  Constants

  # Number of seconds until the next "tradable-tracking cleanup" needs to
  # be performed:
  #TRACKING_CLEANUP_INTERVAL = 61200
  TRACKING_CLEANUP_INTERVAL = 17200 #!!!!test!!!!

  public

  attr_reader :log

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

  # Broker for regular application-related messaging
  def application_message_broker
    MessageBrokerConfiguration::application_message_broker
  end

  # Broker for administrative-level messaging
  def administrative_message_broker
    MessageBrokerConfiguration::administrative_message_broker
  end

  # Broker application-related publish/subscribe-based messaging
  def pubsub_broker
    MessageBrokerConfiguration::pubsub_broker
  end

  # The error-logging object
  def error_log
    MessageBrokerConfiguration::message_based_error_log
  end

  # Is debug-logging enabled?
  def debugging?
    ENV.has_key?(DEBUG_ENV_VAR)
  end

  private

  EOD_ENV_VAR = 'TIINGO_TOKEN'
  DATA_PATH_ENV_VAR = 'MAS_RUNDIR'
  DEBUG_ENV_VAR = 'TAT_DEBUG'

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

  # Initialize 'log' to the_log if ! the_log.nil?.  If the_log is nil,
  # initialize 'log' to MessageBrokerConfiguration::message_based_error_log.
  post :log_set do log != nil end
  def initialize(the_log = nil)
    @log = the_log
    if the_log.nil? then
      @log = MessageBrokerConfiguration::message_based_error_log
    end
  end

end
