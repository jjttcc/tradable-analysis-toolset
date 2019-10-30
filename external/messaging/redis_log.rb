require 'redis'
require 'redis_stream_facilities'
require 'message_log'

class RedisLog
  include Contracts::DSL, RedisStreamFacilities, MessageLog

  public

  #####  Access

  DEFAULT_EXPIRATION_SECS = 24 * 3600

  attr_reader   :key
  attr_accessor :expiration_secs

##!!!!!To-do: Consider adding some or all of the functionality available in
##!!!!!'xread' - i.e., blocking, consumer groups, ids, ...
##!!!!!Re. 'ids', we can save the largest id returned in the last call to
##!!!!!xread and optionally use that value to, in the next call to xread,
##!!!!!retrieve only entries with ids > that value.  Of course, a
##!!!!!reasonable abstraction of this functionality will need to be added
##!!!!!to the MessageLog interface.
  def contents(count: nil)
    redis_log.xrange(key, count)
  end

  #####  Basic operations

  def send_message(log_key: key, tag:, msg:)
    redis_log.xadd(log_key, {tag => msg})
    redis_log.expire(log_key, expiration_secs)
  end

  def send_messages(log_key: key, messages_hash:)
#!!!!!!!!!!!![FOR DEBUG - REMOVE ASAP(2019-september-iteration)]:
puts "<<<START xadd:>>> (No '<<<END xadd>>>' below means exception thrown.)"
    redis_log.xadd(log_key, messages_hash)
puts "<<<END xadd>>>" #!!!!!!!!!!!
    redis_log.expire(log_key, expiration_secs)
  end

  #####  State-changing operations

  def change_key(new_key)
    self.key = new_key
  end

  protected

  attr_reader :redis_log

  private

  attr_writer :redis_log, :key

  # Initialize with the Redis-port, logging key, and, if supplied, the
  # number of seconds until each logged message is set to expire (which
  # defaults to DEFAULT_EXPIRATION_SECS).
  pre :port_exists do |hash| hash[:redis_port] != nil end
  pre :key_exists  do |hash| hash[:key] != nil end
  post :redis_lg  do self.redis_log != nil end
  def initialize(redis_port:, key:, expire_secs: DEFAULT_EXPIRATION_SECS)
    init_facilities(redis_port)
    self.key = key
    self.expiration_secs = expire_secs
  end

end
