require 'ruby_contracts'

module Subscription
  include Contracts::DSL

  public  ###  Access

  # The default 'channel' on which to publish
  attr_reader :default_subscription_channel

  # The last message received via the subscription
  attr_reader :last_message

  # Publish/Subscribe broker
  attr_reader :pubsub_broker

  public  ###  Basic operations

  # Subscribe to 'channel' until the first message is received, calling the
  # block (if it is provided) after setting 'last_message' to the message.
  # Then (after the first message is received & processed) unsubscribe.
  pre  :pubsub_broker do invariant end
  post :last_message  do ! last_message.nil? end
  def subscribe_once(channel = default_subscription_channel, &block)
#!!!!!for debugging - remove soon:!!!!!
puts "#{self.class}.#{__method__}: for #{channel} - stack:"
puts caller
    pubsub_broker.subscribe_once(channel, subs_callbacks) do
      @last_message = pubsub_broker.last_message
puts "Subscription received message: '#{last_message}'"
        if block != nil then
          block.call
        end
    end
  end

  public  ### class invariant

  # pubsub_broker exists.
  def invariant
    pubsub_broker != nil
  end

  protected

  # Callbacks (Hash of lambdas) for subscription events - initialize upon
  # object creation if needed:
  attr_reader :subs_callbacks

  protected   ###  Initialization

  post :broker_set do pubsub_broker != nil end
  def initialize_pubsub_broker(configuration = DataConfig.new)
    @pubsub_broker = configuration.pubsub_broker
  end

end
