require 'json'
require 'ruby_contracts'
require 'concurrent-ruby' #!!!!?
require 'publisher_subscriber'
require 'service'
require 'time_utilities'
require 'logging_facilities'
require 'report_specification'
require 'status_report'


# Management of administrative status reporting - e.g., for debugging,
# statistics, etc.
#!!!!!To-do: add "monitoring" to the services - e.g., when a service
#!!!!sends or receives a message, receives a subscription notice,
#!!!!publishes, etc., it monitors itself - i.e., it logs the event in
#!!!!MessageLog.  This class can then gather this information (or a subset
#!!!!of it, based on what is requested) and "report" it.
class StatusReporting < PublisherSubscriber
  include Service, TimeUtilities, LoggingFacilities

  private

  attr_reader :config, :log_reader  #!!!!????

  ##### Hook method implementations

  def continue_processing
    ordered_status_reporting_run_state != SERVICE_TERMINATED
  end

  def process(args = nil)
    # Subscribe to the STATUS_REPORTING_CHANNEL and provide a response/report
    # when a subscription request arrives.
    subscribe_once do
puts "[SR] a = last_message: '#{last_message}'"
      report_specs = ReportSpecification.new(last_message)
puts "[SR] b - rspecs: #{report_specs.inspect}"
      handler = config.report_handler_for(report_specs)
puts "[SR] c - handler: #{handler.inspect}"
      handler.execute(self)
puts "[SR] d"
#!!!!!redundant:      check_args(report_specs)
=begin
puts "[SR] c - setting obj for #{report_specs.response_key}"
      set_object(report_specs.response_key, report(report_specs))
puts "[SR] d"
=end
    rescue StandardError => e
puts "[SR] specs error: #{e}"
      report_specs_error(e, report_specs)
    end
    sleep MAIN_LOOP_PAUSE_SECONDS
  end

  #####  Implementation

  # Data gathered using specs via 'report_specs'
  pre  :arghash  do |a| a != nil && a.respond_to?(:to_hash) end
  pre  :has_key_list do |a| a[:key_list] != nil && ! a[:key_list].empty? end
  post :resgood do |result| result != nil && result.is_a?(StatusReport) end
  def old____report(report_specs)
    contents = log_reader.contents_for(report_specs.retrieval_args)
    result = config.status_report.new(contents)
puts "[SR] report got a #{result}"
puts "[SR] report's subcounts: #{result.sub_counts}"
    result
  rescue StandardError => e
puts "I found an e: #{e}" #!!!!
puts "Here is our stack:\n#{caller.join("\n")}" #!!!!
    raise e
  end

#!!!!Note: If the ReportSpecification can check its own contents when it
#!!!!is constructed, this will not be needed:
  def check_args(args)
    key_list = args[:key_list]
    if key_list.nil? then
      raise "Missing :key_list argument"
    end
    response_key = args[:response_key]
    if response_key.nil? then
      raise "Missing :response_key argument"
    end
  end

  ERROR_PREFIX = 'Status report failed: '

  def report_specs_error(exception, args)
    error_msg = "#{ERROR_PREFIX}#{exception.to_s}; args: #{args.to_s}"
    error(error_msg)
  end

  MAIN_LOOP_PAUSE_SECONDS = 3

  #####  Initialization

  pre  :config_exists do |config| config != nil end
  post :log_config_etc_set do invariant end
  def initialize(config)
puts "#{self.class} - being born..."
    @config = config
    @log = config.message_log
    @error_log = config.error_log
#!!!!!??:
    @log_reader = config.log_reader
#!!!!!
    self.time_utilities_implementation = config.time_utilities
    @run_state = SERVICE_RUNNING
    @service_tag = STATUS_REPORTING
    # Set up to log with the key 'service_tag'.
    self.log.change_key(service_tag)
    initialize_message_brokers(@config)
    initialize_pubsub_broker(@config)
    set_subscription_callback_lambdas
    init_pubsub(default_subchan: STATUS_REPORTING_CHANNEL,
                default_pubchan: REPORT_RESPONSE_CHANNEL)
    create_status_report_timer
    @status_task.execute
  end

  post :subs_callbacks do subs_callbacks != nil end
  def set_subscription_callback_lambdas
    @subs_callbacks = {}
    @subs_callbacks[:postproc] = lambda do
      # post-sub: Publish notification that the report was completed and sent.
      publish(true)
    end
  end

end
