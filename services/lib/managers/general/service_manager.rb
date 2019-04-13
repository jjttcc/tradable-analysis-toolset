require 'redis'
require 'concurrent-ruby'
require 'data_config'

# Responsible for service management - starting the service and monitoring
# it to ensure that it is always running, restarting if necessary.
class ServiceManager
  include Contracts::DSL, TatServicesFacilities

  public  ###  Access

  attr_reader :tag

  public  ###  Basic operations

  # Ensure the service is started, blocking until it has been verified to
  # be running.
  post :started do is_alive?(tag) end
  def block_until_started
    if ! is_alive?(tag) then
      log.warn("#{tag} is NOT running - starting it up...")
      start_service
      tries = 0
      sleep PING_RETRY_PAUSE
      while ! is_alive?(tag)
        if tries > LIFE_CHECK_LIMIT then
          raise "#{tag} failed to start"
        end
        sleep PING_RETRY_PAUSE
        tries += 1
      end
    else
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
        log.warn(msg)
      end
    end
    @monitoring_task.execute
  end

  ###  Status report

  # Is 'self' "alive" and running properly?
  def healthy?
    @monitoring_task.running?
  end

  private

  attr_reader :redis, :redis_admin, :config

  alias_method :ensure_service_is_running, :block_until_started

  PING_RETRY_PAUSE, LIFE_CHECK_LIMIT = 3, 10
  MONITORING_INTERVAL = 15

  pre  :tag_exists do |t| t != nil && ! t.empty? end
  post :tag_initialized do tag != nil && ! tag.empty? end
  post :admin do ! (config.nil? || log.nil?) end
  def initialize(tag:)
    @tag = tag
    @config = DataConfig.new(log)
    @redis_admin = @config.redis_administration_client
#!!!!Is @redis needed?!!!:
    @redis = @config.redis_application_client
  end

end
