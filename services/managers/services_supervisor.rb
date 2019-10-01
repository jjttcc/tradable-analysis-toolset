require 'ruby_contracts'
require 'service_tokens'
require 'rake_manager'
require 'external_manager'
require 'message_broker_manager'

# Top-level supervision and control of the TAT service processes
# (To-do: implement [or remove, if this class turns out to be unnecessary]
# top-level control of [threaded?] monitoring/control of service processes)
class ServicesSupervisor
  include Contracts::DSL, ServiceTokens
# start/monitor EODRetrievalManager
# start/monitor ExchangeScheduleMonitor
# start/monitor TradableTrackingManager

  private

  attr_reader :continue_supervising, :service_managers, :config

  def supervise
    service_managers.each do |sm|
      sm.monitor
    end
    # Is there any need for this loop?!!!!:
    while continue_supervising do
      check_on_managers
      sleep MAIN_PAUSE_SECONDS
    end
  end

  # Check the status of the 'service_managers' and, ...!!!!!!
  def check_on_managers
    thread_report
    service_managers.each do |sm|
      if ! sm.healthy? then
log_error("#{sm} is NOT healthy!!!! - perhaps I should restart it.")
      end
    end
  end

  def thread_report
    if @iteration_cycle == ITERATION_CYCLE_LENGTH then
      @iteration_cycle = 0
    end
    if @iteration_cycle == 0 then
      threads = Thread.list
      log_error("thread count: #{threads.count} - threads:")
      threads.each do |t|
        log_error(t.inspect)
      end
    end
    @iteration_cycle += 1
  end

  def log_error(msg)
    puts msg
    $stdout.flush
  end

  private

  MAIN_PAUSE_SECONDS = 25
  ITERATION_CYCLE_LENGTH = 6

  private  ###  Initialization

  pre :config_exists do config != nil end
  def initialized_service_managers
    result = []
    result << MessageBrokerManager.new(config)
#!!!eh?: result << MasServerMonitor.new(config, MAS_SERVER_MONITOR)
    result << RakeManager.new(config, EOD_EXCHANGE_MONITORING)
    result << RakeManager.new(config, MANAGE_TRADABLE_TRACKING)
    result << ExternalManager.new(config, EOD_DATA_RETRIEVAL)
    result << RakeManager.new(config, EOD_EVENT_TRIGGERING)
    result << ExternalManager.new(config, STATUS_REPORTING)
#result << RakeManager.new(config, TRIGGER_PROCESSING)
#result << RakeManager.new(config, NOTIFICATION_PROCESSING)
  end

  pre :config_exists do |config| config != nil end
  def initialize(config)
    @iteration_cycle = 0
    @continue_supervising = true
    @config = config
    @log = config.error_log
    # (Array of service managers ordered according to which service should
    # be started when relative to the other services)
    @service_managers = initialized_service_managers
i = 1
    @service_managers.each do |sm|
log_error("i: #{i}")
      begin
        # (I.e., block until sm has ensured that its service has started.)
        log_error("starting #{sm.inspect}")
        sm.block_until_started
      rescue StandardError => e
        log_error("#{sm} startup failed for #{sm.inspect}: #{e} - stack:")
        log_error("#{caller.join("\n")}")
      end
i += 1
    end
    supervise
  end

end
