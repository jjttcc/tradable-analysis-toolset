require 'service_manager'

# ServiceManagers responsible for managing the Redis server - starting it
# and making sure it stays up/available
class RedisManager < ServiceManager

  private  ### Hook method implementations

  def is_alive?(tag)
    ping = redis.ping
    ping2 = redis_admin.ping
    result = ping != nil && ! ping.empty? && ping2 != nil && ! ping2.empty?
    result
  rescue
    false
  end

  def start_service
    if ! is_alive?(tag) then
      # The redis servers are expected to be already running:
      raise "Fatal error: one or both redis servers are not available."
    end
  end

end
