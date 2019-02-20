require_relative 'publication'
require_relative 'subscription'

class PublisherSubscriber
  include Contracts::DSL, Publication, Subscription

#!!!!Next: sadd, srem, smembers, ...
#!!!!And finish/use the constants!!!!!

  private

  post :channels_set do
    ! (default_publishing_channel.nil? || default_subscription_channel.nil?) end
  post :redis do redis != nil end
  def initialize(pubchan = 'default-channel', subchan = 'default-channel')
puts "#{self.class}.new called with pub: #{pubchan}, sub: #{subchan}"
    @redis = Redis.new
    @default_publishing_channel = pubchan
    @default_subscription_channel = subchan
puts "(#{self.class}) redis: #{redis}"
puts "(#{self.class}) default - pubch: #{default_publishing_channel}, " +
"subch: #{default_subscription_channel}"
  end

end
