require 'redis'
require 'redis_message_broker'
require 'redis_pub_sub_broker'
require 'redis_error_log'
require 'redis_log_reader'

class MessageBrokerConfiguration
  include Contracts::DSL

  public  ###  Constants

  # redis application and administration ports
  REDIS_APP_PORT, REDIS_ADMIN_PORT = 16379, 26379
  # Default keys for logs
  DEFAULT_KEY, DEFAULT_ADMIN_KEY = 'tat', 'tat-admin'

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

  # General message-logging object
  def self.message_log(key = DEFAULT_KEY)
    if key.nil? then
      key = DEFAULT_KEY
    end
    RedisLog.new(redis_port: REDIS_APP_PORT, key: key)
  end

  # Administrative message-logging object
  def self.admin_message_log(key = DEFAULT_ADMIN_KEY)
    if key.nil? then
      key = DEFAULT_ADMIN_KEY
    end
    RedisLog.new(redis_port: REDIS_ADMIN_PORT, key: key)
  end

  # Error log using the messaging system
  def self.message_based_error_log
    RedisErrorLog.new(redis_port: REDIS_APP_PORT)
  end

  def self.log_reader
    RedisLogReader.new(redis_port: REDIS_APP_PORT)
  end

  def self.admin_log_reader
    RedisLogReader.new(redis_port: REDIS_ADMIN_PORT)
  end

end
