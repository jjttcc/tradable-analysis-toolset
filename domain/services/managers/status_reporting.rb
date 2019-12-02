require 'json'
require 'ruby_contracts'
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

  protected

  attr_reader :config, :self_terminated

  ##### Hook method implementations

  def continue_processing
#    self_terminated || ordered_status_reporting_run_state != SERVICE_TERMINATED
#!!!!rm: result = self_terminated || ordered_status_reporting_run_state != SERVICE_TERMINATED
    result = ordered_status_reporting_run_state != SERVICE_TERMINATED &&
      ! self_terminated
puts "continue_processing - result: #{result}"
    result
  end

  def old___process(args = nil)
    # Subscribe to the STATUS_REPORTING_CHANNEL and provide a response/report
    # when a subscription request arrives.
    subscribe_once do
      report_specs = ReportSpecification.new(last_message)
      handler = config.report_handler_for(report_specs)
      handler.execute(self)
    rescue StandardError => e
      report_specs_error(e, report_specs)
    end
  end

  def process(args = nil)
    # Subscribe to the STATUS_REPORTING_CHANNEL and provide a response/report
    # when a subscription request arrives.
    subscribe_once do
      child = fork do
        begin
          report_specs = ReportSpecification.new(last_message)
          handler = config.report_handler_for(report_specs)
          handler.execute(self)
        rescue StandardError => e
          report_specs_error(e, report_specs)
        end
      end
      # Let the child take care of the request (and get ready for the next
      # one by allowing the calling loop to invoke 'process' again).  The
      # child will exit after responding to the request.
      Process.detach(child)
    end
  end

  def mem_limit
puts "mem_limit: #{40_000} (#{40_000/1000}m)"
    40_000
  end

  def manage_memory__try1
puts "#{self}.manage_memory - musage: #{mem_usage.to_s}"
    log_messages(memory_usage: mem_usage.to_s)
puts "mem_usage, mem_limit: #{mem_usage}, #{mem_limit}"
puts "mem_usage > mem_limit: #{mem_usage > mem_limit}"
    if mem_usage > mem_limit then
puts "mem_usage > mem_limit calling cleanup_memory... #{self}"
      self.cleanup_memory
puts "#{self}.manage_memory - cleanup_memory completed"
    end
  end

  def manage_memory
puts "#{self}.manage_memory - musage: #{mem_usage.to_s}"
    log_messages(memory_usage: mem_usage.to_s)
puts "mem_usage, mem_limit: #{mem_usage}, #{mem_limit}"
puts "mem_usage > mem_limit: #{mem_usage > mem_limit}"
    if mem_usage > mem_limit then
puts "mem_usage > mem_limit calling cleanup_memory... #{self}"
#      self.cleanup_memory

puts "starting inline mem-cleanup..."
    log_messages(memory_usage: "memory cleanup [#{mem_usage.to_s}]")
puts "#{self.class}.#{__method__} inline mem-cleanup: #{mem_usage.to_s}"
    # Create new instances of attributes that may use significant memory.
    @log = config.message_log
    @error_log = config.error_log
#!!!GC.start
@self_terminated = true
puts "#{__method__} finished (st: #{self.self_terminated})"   #!!!!!!!!!!!
=begin
#or - try this:
@continue_processing = false  # or something to that effect
=end

puts "#{self}.manage_memory - cleanup_memory completed"
    end
  end

  def cleanup_memory
puts "#{self.class}.#{__method__} started - usage: #{mem_usage.to_s}"   #!!!!!
    log_messages(memory_usage: "memory cleanup [#{mem_usage.to_s}]")
    # Create new instances of attributes that may use significant memory.
    @log = config.message_log
    @error_log = config.error_log
#!!!    GC.start
@self_terminated = true
puts "#{__method__} finished (st: #{self.self_terminated})"   #!!!!!!!!!!!
=begin
#or - try this:
@continue_processing = false  # or something to that effect
=end
  end

  #####  Implementation

  ERROR_PREFIX = 'Status report failed: '

  def report_specs_error(exception, args)
    error_msg = "#{ERROR_PREFIX}#{exception.to_s}; args: #{args.to_s}"
    error(error_msg)
  end

  #####  Initialization

  pre  :config_exists do |config| config != nil end
  post :log_config_etc_set do invariant end
  def initialize(config)
    @config = config
    @log = config.message_log
    @error_log = config.error_log
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
    @monitor_memory = false
  end

=begin
#!!!!!TO-DO:!!!!!!!!!!!!!!!!
=end
=begin
# Perform any needed pre-processing before 'process' is called.
  def pre_process(args = nil)
    if monitor_memory then
      log_messages(memory_usage: mem_usage.to_s)
      if mem_usage > mem_limit then
        cleanup_memory
      end
    end
    pre_process_extension
  end
=end

  post :subs_callbacks do subs_callbacks != nil end
  def set_subscription_callback_lambdas
    @subs_callbacks = {}
    @subs_callbacks[:postproc] = lambda do
      # post-sub: Publish notification that the report was completed and sent.
      publish(true)
    end
  end

end
