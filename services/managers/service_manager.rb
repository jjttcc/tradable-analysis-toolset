require 'concurrent-ruby'
require 'tat_services_facilities'
require 'service_state_facilities'

# Responsible for service management - starting the service and monitoring
# it to ensure that it is always running, restarting if necessary.
class ServiceManager
  include Contracts::DSL, TatServicesFacilities
  include ServiceStateFacilities

  public

  #####  Access

  attr_reader :tag

  #####  Boolean queries

  # Is 'self' "alive" and running properly?
  def healthy?
    @monitoring_task.running?
  end

  #####  State-changing operations

  # Ensure the service is started, blocking until it has been verified to
  # be running.
  post :started do is_alive?(tag) end
  def block_until_started
    if ! is_alive?(tag) then
      warn("#{tag} is NOT running - starting it up...")
      start_service
      tries = 0
      sleep PING_RETRY_PAUSE
      while ! is_alive?(tag) do
        if tries > LIFE_CHECK_LIMIT then
          raise "#{tag} failed to start"
        end
        sleep PING_RETRY_PAUSE
        tries += 1
      end
    else
    info("[ServiceManager] service #{tag} is alive")
    end
  end

  # Monitor the service - If it is found to be ill or dead, restart it.
  # Asynchronous - i.e., do not block.
  def monitor
    @monitoring_task = Concurrent::TimerTask.new(execution_interval:
                                                MONITORING_INTERVAL) do |task|
      begin
        ensure_service_is_running
#!!!!Add some method to shut this timer down on command!!!!
      rescue StandardError => e
        msg = "#{tag} service - failed while monitoring: #{e}"
        warn(msg)
      end
    end
    @monitoring_task.execute
  end

  private   ##### Implementation

  attr_reader :config, :error_log

  alias_method :ensure_service_is_running, :block_until_started

  PING_RETRY_PAUSE, LIFE_CHECK_LIMIT = 3, 10
  MONITORING_INTERVAL = 15

  pre  :config_exists do |config| config != nil end
  pre  :tag_exists do |c, t| (t != nil && ! t.empty?) ||
    (default_tag != nil && ! default_tag.empty?) end
  post :tag_initialized do tag != nil && ! tag.empty? end
  post :admin do ! (config.nil? || log.nil? || error_log.nil?) end
  def initialize(config, tag = default_tag)
    @tag = tag
    @config = config
    @log = @config.message_log
    @error_log = @config.error_log
    initialize_message_brokers(config)
  end

end
