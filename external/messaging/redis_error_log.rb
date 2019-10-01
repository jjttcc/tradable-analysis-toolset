require 'error_log'
require 'redis_log'

class RedisErrorLog < RedisLog
  include ErrorLog

  public

  alias_method :send, :send_message

  ERROR_LOG_STREAM = 'logging-stream'

  pre :port_exists do |hash| hash[:redis_port] != nil end
  def initialize(redis_port:, key: ERROR_LOG_STREAM,
                 expire_secs: DEFAULT_EXPIRATION_SECS)
    super(redis_port: redis_port, key: key, expire_secs: expire_secs)
  end

end
