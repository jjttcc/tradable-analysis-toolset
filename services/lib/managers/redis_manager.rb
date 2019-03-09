require 'service_manager'

# ServiceManagers responsible for managing the Redis server - starting it
# and making sure it stays up/available
class RedisManager < ServiceManager
end
