# Facilities - utility methods, etc. - related to use of Redis
# Note: Classes that include this module must define the query 'redis
# (i.e., as an attribute or argument-less function/method).
module RedisFacilities

  public  ###  Access

  # The message previously added via 'set_message(key, msg)'
  def retrieved_message(key)
    result = redis.get key
    result
  end

  # The set previously built via 'replace_set(key, args)' and/or
  # 'add_set(key, args)'
  def retrieved_set(key)
    redis.smembers key
  end

  public  ###  Status report

  # The number of members in the set identified by 'key'
  def cardinality(key)
    redis.scard key
  end

  public  ###  Element change

  # Set (insert) a keyed message
  def set_message(key, msg, options = {})
    redis.set key, msg, options
  end

  # Add, with 'key', the specified set with items 'args'.  If the set
  # (with 'key') already exists, simply add to the set any items from 'args'
  # that aren't already in the set.
  # Return the resulting count value (of items actually added) from Redis.
  def add_set(key, args)
    redis.sadd key, args
  end

  # Add, with 'key', the specified set with items 'args'.  If the set
  # (with 'key') already exists, remove the old set first before creating
  # the new one.
  # Return the resulting count value (of items actually added) from Redis.
  def replace_set(key, args)
    redis.del key
    redis.sadd key, args
  end

  # Remove members 'args' from the set specified by 'key'.
  def remove_from_set(key, args)
    redis.srem key, args
  end

  # Delete the object (message inserted via 'set_message', set added via
  # 'add_set', or etc.) with the specified key.
  def delete_object(key)
    redis.del key
  end

end
