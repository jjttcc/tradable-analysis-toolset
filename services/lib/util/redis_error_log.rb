require 'error_log'
require 'redis'

class RedisErrorLog < ErrorLog

  protected

  def send(tag, msg)
    @redis_log.xadd(ERROR_LOG_STREAM, {tag => msg})
  end

  private

  ERROR_LOG_STREAM = 'logging-stream'

  def initialize(redis_port:)
    @redis_log = Redis.new(port: redis_port)
  end

end
