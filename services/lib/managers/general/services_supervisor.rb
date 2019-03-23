require 'ruby_contracts'
require 'service_tokens'
require 'redis_facilities'
require 'tat_services_facilities'
require 'redis_manager'
require 'rake_manager'
require 'external_manager'

# Top-level supervision and control of the TAT service processes
# (To-do: implement [or remove, if this class turns out to be unnecessary]
# top-level control of [threaded?] monitoring/control of service processes)
class ServicesSupervisor
  include Contracts::DSL, ServiceTokens
# start/monitor redis
# start/monitor EODRetrievalManager
# start/monitor ExchangeScheduleMonitor
# start/monitor TradableTrackingManager

  private

  attr_reader :continue_supervising, :service_managers

#!!!!Each "service supervisor" will probably run in its own thread!!!!!

  def supervise
    service_managers.each do |sm|
      sm.monitor
    end
    # Is there any need for this loop?!!!!:
    while continue_supervising
      check_on_managers
      sleep MAIN_PAUSE_SECONDS
    end
  end

  # Check the status of the 'service_managers' and, ...!!!!!!
  def check_on_managers
    log("threads: #{Thread.list.join("\n")}")
    service_managers.each do |sm|
      if ! sm.healthy? then
puts "#{sm} is NOT healthy!!!! - perhaps I should restart it."
STDOUT.flush
      end
    end
  end

  def initialized_service_managers
    result = []
    result << RedisManager.new(tag: REDIS)
#!!!!eh?: result << MasServerMonitor.new(tag: MAS_SERVER_MONITOR)
    result << RakeManager.new(tag: EOD_EXCHANGE_MONITORING)
    result << RakeManager.new(tag: MANAGE_TRADABLE_TRACKING)
    result << ExternalManager.new(tag: EOD_DATA_RETRIEVAL)
  end

#!!!!TO-BE-FIXED:!!!!
  def log(msg)
    puts msg
  end

  private

  MAIN_PAUSE_SECONDS = 25

  private  ###  Initialization

  def initialize
    @continue_supervising = true
    # (Array of service managers ordered according to which service should
    # be started when relative to the other services)
    @service_managers = initialized_service_managers
    @service_managers.each do |sm|
      begin
        # (I.e., block until sm has ensured that its service has started.)
puts "starting #{sm.inspect}"
        sm.block_until_started
      rescue StandardError => e
        log("#{sm} startup failed: #{e}")
      end
    end
    supervise
  end

end
