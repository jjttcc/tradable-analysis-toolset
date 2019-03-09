require 'redis'

# Responsible for service management - starting the service and monitoring
# it to ensure that it is always running, restarting if necessary.
class ServiceManager
  include Contracts::DSL, TatServicesFacilities

  public

#!!!!
  def block_until_started
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  attr_reader :tag, :redis

  private

  pre  :tag_exists do |t| t != nil && ! t.empty? end
  post :tag_initialized do tag != nil && ! tag.empty? end
  def initialize(tag:)
    @tag = tag
    @redis = Redis.new
puts "tag: #{tag}"
  end

end
