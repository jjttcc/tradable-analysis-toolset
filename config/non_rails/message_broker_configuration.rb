require 'redis'
require 'redis_message_broker'
require 'redis_pub_sub_broker'
require 'redis_error_log'

class MessageBrokerConfiguration
  include Contracts::DSL

  public  ###  Constants

  # redis application and administration ports
  REDIS_APP_PORT, REDIS_ADMIN_PORT = 16379, 26379

  public

  # Broker for regular application-related messaging
  def self.application_message_broker
    RedisMessageBroker.new(Redis.new(port: REDIS_APP_PORT))
  end

  # Broker for administrative-level messaging
  def self.administrative_message_broker
    RedisMessageBroker.new(Redis.new(port: REDIS_ADMIN_PORT))
  end

  # Broker application-related publish/subscribe-based messaging
  def self.pubsub_broker
    RedisPubSubBroker.new(Redis.new(port: REDIS_APP_PORT))
  end

  # Error log using the messaging system
  def self.message_based_error_log
    RedisErrorLog.new(redis_port: REDIS_APP_PORT)
  end

end
