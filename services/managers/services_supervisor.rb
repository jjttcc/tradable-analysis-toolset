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
    log_startup(true)
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
        log.debug("#{sm} is NOT healthy!!!! - perhaps I should restart it.")
      end
    end
  end

  def thread_report
    if @iteration_cycle == ITERATION_CYCLE_LENGTH then
      @iteration_cycle = 0
    end
    if @iteration_cycle == 0 then
      threads = Thread.list
      log.debug("thread count: #{threads.count} - threads:")
      threads.each do |t|
        log.debug(t.inspect)
      end
    end
    @iteration_cycle += 1
  end

  private

  MAIN_PAUSE_SECONDS = 25
  ITERATION_CYCLE_LENGTH = 6

  attr_reader :log

  private  ###  Initialization

  pre :config_exists do config != nil end
  def initialized_service_managers
    result = []
    result << MessageBrokerManager.new(config)
##!!!!![moved here: (check)]:
result << ExternalManager.new(config, STATUS_REPORTING)
#!!!eh?: result << MasServerMonitor.new(config, MAS_SERVER_MONITOR)

    result << RakeManager.new(config, EOD_EXCHANGE_MONITORING)
    result << RakeManager.new(config, MANAGE_TRADABLE_TRACKING)
    result << ExternalManager.new(config, EOD_DATA_RETRIEVAL)
##XXX!!!    result << RakeManager.new(config, EOD_EVENT_TRIGGERING)

#result << RakeManager.new(config, TRIGGER_PROCESSING)
#result << RakeManager.new(config, NOTIFICATION_PROCESSING)
  end

  pre :config_exists do |config| config != nil end
  def initialize(config)
    @iteration_cycle = 0
    @continue_supervising = true
    @config = config
    @log = config.error_log
    log_startup
    # (Array of service managers ordered according to which service should
    # be started when relative to the other services)
    @service_managers = initialized_service_managers
    @service_managers.each do |sm|
      begin
        # (I.e., block until sm has ensured that its service has started.)
        @log.debug("starting #{sm.inspect}")
        sm.block_until_started
      rescue StandardError => e
        msg = "#{sm} startup failed for #{sm.inspect}: #{e} - stack:"
        msg += "\n#{caller.join("\n")}"
        @log.error(msg)
        $stderr.puts msg
      end
    end
    supervise
  end

  pre :log do @log != nil end
  def log_startup(complete = false)
    id = "#{self.class} (pid: #{$$})"
    if complete then
      msg = "#{id}: All #{service_managers.count} services initiated."
    else
      msg = "#{id}: Starting up services."
    end
    log.info(msg)
  end

end
