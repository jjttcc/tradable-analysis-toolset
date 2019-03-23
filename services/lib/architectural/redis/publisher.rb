require 'redis'
require 'ruby_contracts'
require_relative 'publication'

class Publisher
  include Contracts::DSL, Publication

  private

  def initialize(pubchan = 'default-channel')
#!!!    if @redis.nil? then
#!!!      @redis = Redis.new(port: redis_app_port)
#!!!    end
    @default_publishing_channel = pubchan
puts "(#{self.class} [#{__FILE__}]) redis: #{redis}"
puts "(#{self.class}) default - pubch: #{default_publishing_channel}, "
  end

  def redis_app_port
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

end
