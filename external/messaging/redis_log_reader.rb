require 'log_reader'
require 'redis'

class RedisLogReader
  include Contracts::DSL, LogReader

  public

  #####  Access

  def contents(key:, count: nil)
    redis_log.xrange(key, count: count)
  end

##!!!!!To-do: Consider adding some or all of the functionality available in
##!!!!!'xread' - i.e.: consumer groups; use of saved ids (e.g., in a private
##!!!!!array attribite) to be used in the next 'contents_for' call; ...
##!!!!!(An abstract representation of this functionality will need to go
##!!!!!into 'LogReader'.)

  def contents_for(key_list:, count: nil, block_msecs: nil, new_only: false)
    if key_list != nil && ! key_list.empty? then
      if new_only then
        ids = key_list.map { '$' }
      else
###!!!!!Here is one place we would need to deal with the saved
#!!!!! "last-read-id(for-key)" if we implement that!!!!!!
        ids = key_list.map { '0' }
      end
      result = redis_log.xread(key_list, ids, count: count, block: block_msecs)
    end
  end

  protected

  attr_reader :redis_log

  private

  attr_writer :redis_log

  # Initialize with the Redis-port, logging key, and, if supplied, the
  # number of seconds until each logged message is set to expire (which
  # defaults to DEFAULT_EXPIRATION_SECS).
  pre :port_exists do |hash| hash[:redis_port] != nil end
  post :redis_lg  do self.redis_log != nil end
  def initialize(redis_port:)
    self.redis_log = Redis.new(port: redis_port)
puts "RedisLogReader.initialize called - redis_log: #{redis_log}"
  end

end
