require 'redis'
require 'ruby_contracts'

module Subscription
  include Contracts::DSL

  public  ###  Access

  # The default 'channel' on which to publish
  attr_reader :default_subscription_channel

  # The last message received via the subscription
  attr_reader :last_message

  # The Redis-client object
  attr_reader :redis

  # Should the current subscription be ended?
  attr_accessor :end_subscription

  public  ###  Basic operations

  # Subscribe to 'channel' until the first message is received, calling the
  # block (if it is provided) after setting 'last_message' to the message.
  # Then (after the first message is received & processed) unsubscribe.
  pre  :redis_exists do ! redis.nil? end
  post :last_message do ! last_message.nil? end
  def subscribe_once(channel = default_subscription_channel, &block)
    prepare_for_subscription(channel)
    redis.subscribe channel do |on|
      on.message do |channel, message|
        @last_message = message
puts "subscriber received message: '#{message}'"
        if block != nil then
          block.call
        end
        process_subscription
        redis.unsubscribe channel
      end
    end
    post_process_subscription(channel)
  end

  # Subscribe to 'channel'.  On receiving a message:
  #   - Set 'last_message' to the message contents.
  #   - Call the block (if it is provided).
  #   - Call 'process_conditional_subscription'.
  #   - If 'end_subscription' is true (i.e., set by either the block or
  #     'process_conditional_subscription), unsubscribe to 'channel'.
  pre  :redis_exists do ! redis.nil? end
  post :last_message do ! last_message.nil? end
  def subscribe_until_stopped(channel = default_subscription_channel, &block)
    prepare_for_subscription(channel)
    redis.subscribe channel do |on|
      on.message do |channel, message|
        @last_message = message
puts "subscriber received message: '#{message}'"
        if block != nil then
          block.call
        end
        process_conditional_subscription
        if end_subscription then
          redis.unsubscribe channel
        end
      end
    end
    post_process_subscription(channel)
  end

  # Called by 'subscribe_until_stopped' after calling the block passed
  # to 'redis.subscribe'.
  pre :last_message do last_message != nil end
  def process_conditional_subscription
    # null-op - redefine re. template-method pattern if needed
  end

  protected  ### Hook methods

  # Called by 'subscribe_once' and 'subscribe_until_stopped' before calling
  # redis.subscribe.
  def prepare_for_subscription(channel)
    # null-op - redefine re. template-method pattern if needed
  end

  # Called by 'subscribe_once' and 'subscribe_until_stopped' after calling
  # redis.subscribe.
  def post_process_subscription(channel)
    # null-op - redefine re. template-method pattern if needed
  end

  # Called by 'subscribe_once' after calling the block passed
  # to 'redis.subscribe'.
  pre :last_message do last_message != nil end
  def process_subscription
    # null-op - redefine re. template-method pattern if needed
  end

end
