# Facilities - utility methods, etc. - related to use of Redis
# Note: Classes that include this module must define the query 'redis'
# (i.e., as an attribute or argument-less function/method).
module RedisFacilities
  include Contracts::DSL

  public  ###  Access

  # The message previously added via 'set_message(key, msg)'
  pre :at_least_one_redis do |k, redis_cl| ! (redis_cl.nil? && redis.nil?) end
  def retrieved_message(key, redis_client = redis)
    result = redis_client.get key
    result
  end

  # The set previously built via 'replace_set(key, args)' and/or
  # 'add_set(key, args)'
  pre :at_least_one_redis do |k, redis_cl| ! (redis_cl.nil? && redis.nil?) end
  post :result_exists do |result| ! result.nil? && result.is_a?(Array) end
  def retrieved_set(key, redis_client = redis)
    redis_client.smembers key
  end

  public  ###  Status report

  # The number of members in the set identified by 'key'
  pre :at_least_one_redis do |k, redis_cl| ! (redis_cl.nil? && redis.nil?) end
  post :result_exists do |result| ! result.nil? && result >= 0 end
  def cardinality(key, redis_client = redis)
    redis_client.scard key
  end

  public  ###  Element change

  # Set (insert) a keyed message
  pre :at_least_one_redis do |k, m, o, r_cl| ! (r_cl.nil? && redis.nil?) end
  def set_message(key, msg, options = {}, redis_client = redis)
    if @@redis_debug then
      puts "set_message - calling redis_client.set with #{key}, " +
        "#{msg}, #{options}, redis_client: #{redis_client}"
    end
    redis_client.set key, msg, options
    if @@redis_debug then
      puts "[set_message - survived redis_client.set!]"
    end
  end

  # Add 'msgs' (a String, if 1 message, or an array of Strings) to the end of
  # the list with key 'key'.
  # If 'expiration' is not nil, set the time-to-live for the set to
  # 'expiration'.
  # Return the resulting size of the list.
  pre :at_least_one_redis do |k, m, e, r_cl| ! (r_cl.nil? && redis.nil?) end
  def queue_messages(key, msgs, expiration, redis_client = redis)
    result = redis_client.lpush(key, msgs)
    if expiration != nil then
      redis_client.expire key, expiration
    end
    result
  end

  # The next element (head) in the queue with key 'key' (typically,
  # inserted via 'queue_messages')
  pre :at_least_one_redis do |k, redis_cl| ! (redis_cl.nil? && redis.nil?) end
  def queue_head(key, redis_client = redis)
    redis_client.lrange(key, -1, -1).first
  end

  # The last element (tail) in the queue with key 'key' (typically,
  # inserted via 'queue_messages')
  pre :at_least_one_redis do |k, redis_cl| ! (redis_cl.nil? && redis.nil?) end
  def queue_tail(key, redis_client = redis)
    redis_client.lrange(key, 0, 0).first
  end

  # The count (size) of the queue with key 'key'
  pre :at_least_one_redis do |k, redis_cl| ! (redis_cl.nil? && redis.nil?) end
  def queue_count(key, redis_client = redis)
    redis_client.llen(key)
  end

  # Remove the next element (head) of the queue with key 'key' (typically,
  # inserted via 'queue_messages').  Return the value of that element.
  pre :at_least_one_redis do |k, redis_cl| ! (redis_cl.nil? && redis.nil?) end
  def remove_next_from_queue(key, redis_client = redis)
    redis_client.rpop(key)
  end

  # Move the next (head) element from the queue @ key1 to the tail of the
  # queue @ key2.  If key1 == key2, move the head to the tail of the same
  # queue.
  pre :at_least_one_redis do |k, redis_cl| ! (redis_cl.nil? && redis.nil?) end
  pre :keys_exist do |key1, key2| ! (key1.nil? || key2.nil?) end
  def move_head_to_tail(key1, key2, redis_client = redis)
    ttl = -3
    if ! redis_client.exists(key2) && redis_client.exists(key1) then
      ttl = redis_client.ttl(key1)
    end
    redis_client.rpoplpush(key1, key2)
puts "mhtt - ttl: #{ttl.inspect}"
    if ttl > 0 then
      # queue @ key2 is new - set its time-to-live to that of key1.
      redis_client.expire(key2, ttl)
    end
  end

  # Rotate the queue @ key such that the former head is moved to the tail of
  # the queue and former second element becomes the head, etc.
  # Note: This operation [rotate_queue(key)] is the same as calling:
  #   move_head_to_tail(key, key)
  pre :at_least_one_redis do |k, redis_cl| ! (redis_cl.nil? && redis.nil?) end
  pre :key_exists do |key| ! key.nil? end
  def rotate_queue(key, redis_client = redis)
    move_head_to_tail(key, key)
  end

  # All elements of the queue identified with 'key', in their original
  # order - The queue's state is not changed.
  pre :at_least_one_redis do |k, redis_cl| ! (redis_cl.nil? && redis.nil?) end
  def queue_contents(key, redis_client = redis)
    # ('.reverse' because the list representation reverses the elements' order.)
    redis_client.lrange(key, 0, -1).reverse
  end

  # Add, with 'key', the specified set with items 'args'.  If the set
  # (with 'key') already exists, simply add to the set any items from 'args'
  # that aren't already in the set.
  # If 'expiration' is not nil, set the time-to-live for the set to
  # 'expiration'.
  # Return the resulting count value (of items actually added) from Redis.
  pre :at_least_one_redis do |k, m, o, r_cl| ! (r_cl.nil? && redis.nil?) end
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
  pre :at_least_one_redis do |k, a, r_cl| ! (r_cl.nil? && redis.nil?) end
  def replace_set(key, args, redis_client = redis)
    redis_client.del key
    redis_client.sadd key, args
  end

  # Remove members 'args' from the set specified by 'key'.
  pre :at_least_one_redis do |k, a, r_cl| ! (r_cl.nil? && redis.nil?) end
  def remove_from_set(key, args, redis_client = redis)
    redis_client.srem key, args
  end

  # Delete the object (message inserted via 'set_message', set added via
  # 'add_set', or etc.) with the specified key.
  pre :at_least_one_redis do |k, redis_cl| ! (redis_cl.nil? && redis.nil?) end
  def delete_object(key, redis_client = redis)
    redis_client.del key
  end

  protected

  @@redis_debug = false

end
