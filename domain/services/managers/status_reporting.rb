require 'json'
require 'ruby_contracts'
require 'concurrent-ruby' #!!!!?
require 'subscriber'
require 'service'
require 'time_utilities'
require 'logging_facilities'
require 'report_specification'


# Management of administrative status reporting - e.g., for debugging,
# statistics, etc.
#!!!!!To-do: add "monitoring" to the services - e.g., when a service
#!!!!sends or receives a message, receives a subscription notice,
#!!!!publishes, etc., it monitors itself - i.e., it logs the event in
#!!!!MessageLog.  This class can then gather this information (or a subset
#!!!!of it, based on what is requested) and "report" it.
class StatusReporting < Subscriber
  include Service, TimeUtilities, LoggingFacilities

  private

  attr_reader :config, :log_reader

  ##### Hook method implementations

  def continue_processing
    ordered_status_reporting_run_state != SERVICE_TERMINATED
  end

  def process(args = nil)
    # Subscribe to the STATUS_REPORTING_CHANNEL and provide a response/report
    # when a subscription request arrives.
    subscribe_once do
puts "(#{__method__}, in block) lastmsg:<<<\n#{last_message}>>>"  #!!!!!!!!!!!
      report_specs = ReportSpecification.new(last_message)
      check_args(report_specs)
      send_report(report_specs, report(report_specs.retrieval_args))
    rescue StandardError => e
puts "stack:\n#{caller.join("\n")}" #!!!!!!!!!!!
      report_specs_error(e, report_specs)
    end
    sleep MAIN_LOOP_PAUSE_SECONDS
  end

  #####  Implementation

  # Data gathered using specs via 'report_specs'
  pre  :arghash  do |a| a != nil && a.respond_to?(:to_hash) end
  pre  :has_key_list do |a| a[:key_list] != nil && ! a[:key_list].empty? end
  post :resgood do |result| result != nil && result.is_a?(Hash) end
  def report(report_specs)
puts "repargs.class: #{report_specs.class}"  #!!!!!!!!
puts "repargs: #{report_specs.inspect}"      #!!!!!!!!
#!!!!test contents (instead of contents_for):
#!!!      result = log_reader.contents(key: report_specs)
    result = log_reader.contents_for(report_specs)
    result
  end

  # Log the report result.
  pre :specs do |specs| specs != nil && specs.is_a?(ReportSpecification) end
  pre :info  do |s, info| info != nil && info.is_a?(Hash) end
  def send_report(specs, info)
puts "specs key, specs: #{specs.response_key}, #{specs.inspect}"  #!!!!!!
puts "send_report: info:\n#{info.inspect}"  #!!!!!!
puts "send_report: logging with key '#{specs.response_key}'"
#!!!!The 2nd argument needs work/formatting/whatever:
    log.send_messages_with_key(specs.response_key, {:UGLY_KEY => info.to_json})
  end

  def check_args(args)
puts "args, args[:key_list]:\n#{args.inspect}, #{args[:key_list]}"
    key_list = args[:key_list]
    if key_list.nil? then
      raise "Missing :key_list argument"
    end
#    response_key = args[:response_key]
#    if response_key.nil? then
#      raise "Missing :response_key argument"
#    end
  end

  ERROR_PREFIX = 'Status report failed: '

  def report_specs_error(exception, args)
    error_msg = "#{ERROR_PREFIX}#{exception.to_s}; args: #{args.to_s}"
puts "error_msg: #{error_msg}"  #!!!!!!!!!!!!!!
    error(error_msg)
  end

  MAIN_LOOP_PAUSE_SECONDS = 3

  #####  Initialization

  pre  :config_exists do |config| config != nil end
  post :log_config_etc_set do invariant end
  def initialize(config)
    @config = config
    @log = config.message_log
    @error_log = config.error_log
    @log_reader = config.log_reader
    self.time_utilities_implementation = config.time_utilities
#!!!!![2019-september-iteration]!!!!:
dbmsg = "[DEBUG] StatusReporting init - log: #{log.inspect}"
log.send_message(current_date_time, dbmsg)
    @run_state = SERVICE_RUNNING
    @service_tag = STATUS_REPORTING
    self.log.change_key(service_tag)
    initialize_message_brokers(@config)
    initialize_pubsub_broker(@config)
    set_subscription_callback_lambdas
    super(STATUS_REPORTING_CHANNEL)  # i.e., subscribe channel
    create_status_report_timer
    @status_task.execute
  end

  post :subs_callbacks do subs_callbacks != nil end
  def set_subscription_callback_lambdas
    @subs_callbacks = {}
    @subs_callbacks[:postproc] = lambda do
      #!!!!What to do for reporting!!!!?????!!!!!!!!!!
    end
  end

end
