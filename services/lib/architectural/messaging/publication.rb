require 'ruby_contracts'

module Publication
  include Contracts::DSL

  public

  # The default 'channel' on which to publish
  attr_reader :default_publishing_channel

  # Publish/Subscribe broker
  attr_reader :pubsub_broker

  pre :pubsub_broker do invariant end
  pre :pub_msg do |message| ! message.nil? end
  def publish(message, channel = default_publishing_channel)
puts "[#{self.class}] publishing on #{channel}, '#{message}' - stack:"
puts "#{__FILE__}:#{__LINE__}"
puts caller
    pubsub_broker.publish channel, message
  end

  public  ### class invariant

  # pubsub_broker exists.
  def invariant
    pubsub_broker != nil
  end

  protected   ###  Initialization

  post :broker_set do pubsub_broker != nil end
  def initialize_pubsub_broker(configuration = DataConfig.new)
    @pubsub_broker = configuration.pubsub_broker
  end

end
