require 'redis'
require 'ruby_contracts'

module Publication
  include Contracts::DSL

  public

  # The default 'channel' on which to publish
  attr_reader :default_publishing_channel

  # The Redis-client object
  attr_reader :redis

  pre  :redis_exists do ! redis.nil? end
  pre :pub_msg do |message| ! message.nil? end
  def publish(message, channel = default_publishing_channel)
puts "publishing on #{channel}, '#{message}'"
    redis.publish channel, message
  end

end
