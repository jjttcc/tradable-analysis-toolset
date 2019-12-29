PRODUCTION_VAR_NAME = 'TAT_PRODUCTION'
if $is_production_run.nil? then
  $is_production_run =  ENV.has_key?(PRODUCTION_VAR_NAME)
end

require 'service_configuration'
require 'utility_configuration'
require 'tiingo_data_retriever'
require 'file_tradable_storage'
require 'message_broker_configuration'
require 'conventional_database_configuration'
require 'in_memory_database_configuration'
require 'time_util'

# Application-level/plug-in configuration
class ApplicationConfiguration
  include Contracts::DSL

  public

  #####  Constants

  # Number of seconds until the next "tradable-tracking cleanup" needs to
  # be performed:
  #TRACKING_CLEANUP_INTERVAL = 61200
  TRACKING_CLEANUP_INTERVAL = 17200 #!!!!test!!!!

  #####  Constants - instance access

  def tracking_cleanup_interval
    TRACKING_CLEANUP_INTERVAL
  end

  #####  Access - objects

  attr_reader :log, :database_type

  ## database types:
  CONVENTIONAL_DB, IN_MEMORY_DB = :conventional, :in_memory

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

  # General message-logging object
  def message_log(key = nil)
    MessageBrokerConfiguration::message_log(key)
  end

  # Administrative message-logging object
  def admin_message_log(key = nil)
    MessageBrokerConfiguration::admin_message_log(key)
  end

  # The error-logging object
  def error_log
    MessageBrokerConfiguration::message_based_error_log
  end

  # The error-logging object
  def log_reader
    MessageBrokerConfiguration::log_reader
  end

  # ReportRequestHandler descendant object, according to 'specs.type'
  def report_handler_for(specs)
    UtilityConfiguration::report_handler_for(specs: specs, config: self)
  end

  #####  Access - classes or modules

  # StatusReport descendant of the appropriate class for the application
  def status_report
    UtilityConfiguration::status_report
  end

  # data serializer
  def serializer
    UtilityConfiguration::serializer
  end

  # data de-serializer
  def de_serializer
    UtilityConfiguration::de_serializer
  end

  # RAM usage of current process in kilobytes
  def mem_usage
    UtilityConfiguration::mem_usage
  end

  # Database configuration/factory (class)
  post :is_class do |result| result.is_a?(Class) end
  def database
    if database_type == CONVENTIONAL_DB then
      result = ConventionalDatabaseConfiguration
    elsif database_type == IN_MEMORY_DB then
      result = InMemoryDatabaseConfiguration
    else
      raise "Code defect: Invalid 'database_type'"
    end
    result
  end

  # Service-management configuration
  post :is_class do |result| result.is_a?(Class) end
  post :is_srvc_conf do |result| result == ServiceConfiguration end
  def service_management
    ServiceConfiguration
  end

  # Service-management configuration
  post :is_module do |result| result.is_a?(Module) end
  def time_utilities
    TimeUtil
  end

  #####  Basic queries

  def valid_database_type?(type)
    type != nil && @@database_types[type]
  end

  #####  Boolean queries

  # Is debug-logging enabled?
  def debugging?
    ENV.has_key?(DEBUG_ENV_VAR)
  end

  private #####  Implementation

  EOD_ENV_VAR = 'TIINGO_TOKEN'
  DATA_PATH_ENV_VAR = 'MAS_RUNDIR'
  DEBUG_ENV_VAR = 'TAT_DEBUG'
  @@database_types = { CONVENTIONAL_DB => true, IN_MEMORY_DB => true}

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
  pre  :db_type_valid_or_nil do |log, db_type|
    implies(db_type != nil, valid_database_type?(db_type)) end
  post :log_set do log != nil end
  post :db_type do |result, log, db_type|
    implies(db_type != nil, database_type == db_type) end
  post :db_type_valid do valid_database_type?(database_type) end
  post :default_conventional do |result, log, db_type|
    implies(db_type.nil?, database_type == CONVENTIONAL_DB) end
  def initialize(the_log = nil, db_type = nil)
    @log = the_log
    if the_log.nil? then
      @log = MessageBrokerConfiguration::message_based_error_log
    end
    if db_type.nil? then
      @database_type = CONVENTIONAL_DB
    else
      @database_type = db_type
    end
  end

end
