# Facilities - utility methods, etc. - related to use of Redis
# Note: Classes that include this module must define the query 'redis'
# (i.e., as an attribute or argument-less function/method).
module RedisFacilities
  include Contracts::DSL

  public  ###  Access

  # The message previously added via 'set_message(key, msg)'
  def retrieved_message(key, redis_client = redis)
    result = redis_client.get key
    result
  end

  # The set previously built via 'replace_set(key, args)' and/or
  # 'add_set(key, args)'
  post :result_exists do |result| ! result.nil? && result.is_a?(Array) end
  def retrieved_set(key, redis_client = redis)
    redis_client.smembers key
  end

  public  ###  Status report

  # The number of members in the set identified by 'key'
  post :result_exists do |result| ! result.nil? && result >= 0 end
  def cardinality(key, redis_client = redis)
    redis_client.scard key
  end

  public  ###  Element change

  # Set (insert) a keyed message
  def set_message(key, msg, options = {}, redis_client = redis)
puts "set_message - calling redis_client.set with #{key}, #{msg}, #{options}"
puts "[set_message - redis: #{redis}]"
    redis_client.set key, msg, options
puts "[set_message - survived redis_client.set!]"
  end

  # Add, with 'key', the specified set with items 'args'.  If the set
  # (with 'key') already exists, simply add to the set any items from 'args'
  # that aren't already in the set.
  # If 'expiration' is not nil, set the time-to-live for the set to
  # 'expiration'.
  # Return the resulting count value (of items actually added) from Redis.
  def add_set(key, args, expiration, redis_client = redis)
    result = redis_client.sadd key, args
    if expiration != nil then
      redis_client.expire key, expiration
    end
    result
  end

  # Add, with 'key', the specified set with items 'args'.  If the set
  # (with 'key') already exists, remove the old set first before creating
  # the new one.
  # Return the resulting count value (of items actually added) from Redis.
  def replace_set(key, args, redis_client = redis)
    redis_client.del key
    redis_client.sadd key, args
  end

  # Remove members 'args' from the set specified by 'key'.
  def remove_from_set(key, args, redis_client = redis)
    redis_client.srem key, args
  end

  # Delete the object (message inserted via 'set_message', set added via
  # 'add_set', or etc.) with the specified key.
  def delete_object(key, redis_client = redis)
    redis_client.del key
  end

end
