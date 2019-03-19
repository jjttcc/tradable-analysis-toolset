require 'redis'
require 'ruby_contracts'
require_relative 'subscription'

class Subscriber
  include Contracts::DSL, Subscription

  def initialize(subchan = 'default-channel')
    if @redis.nil? then
      @redis = Redis.new(port: redis_app_port)
    end
    @default_subscription_channel = subchan
puts "(#{self.class}) redis: #{redis}"
puts "subch: #{default_subscription_channel}"
  end

  def redis_app_port
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

end
