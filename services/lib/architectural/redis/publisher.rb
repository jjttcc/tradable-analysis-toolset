require 'redis'
require 'ruby_contracts'
require_relative 'publication'

class Publisher
  include Contracts::DSL, Publication

  private

  def initialize(pubchan = 'default-channel')
    @redis = Redis.new
    @default_publishing_channel = pubchan
puts "(#{self.class} [#{__FILE__}]) redis: #{redis}"
puts "(#{self.class}) default - pubch: #{default_publishing_channel}, "
  end

end
