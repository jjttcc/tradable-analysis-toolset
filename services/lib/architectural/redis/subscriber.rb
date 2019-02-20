require 'redis'
require 'ruby_contracts'
require_relative 'subscription'

class Subscriber
  include Contracts::DSL, Subscription

  def initialize(subchan = 'default-channel')
    @redis = Redis.new
    @default_subscription_channel = subchan
puts "(#{self.class}) redis: #{redis}"
puts "subch: #{default_subscription_channel}"
  end

end
