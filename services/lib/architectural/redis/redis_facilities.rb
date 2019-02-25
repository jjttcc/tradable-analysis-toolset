# Facilities - utility methods, etc. - related to use of Redis
# Note: Classes that include this module must define the query 'redis
# (i.e., as an attribute or argument-less function/method).
module RedisFacilities
  public

  # Set (insert) a keyed message
  def set_message(key, args)
puts "sendmessage calling: redis.set #{key}, *#{args}"
    redis.set key, *args
  end

  # Add, with 'key', the specified set with items 'args'.  If the set
  # (with 'key') already exists, simply add to the set any items from 'args'
  # that aren't already in the set.
  # Return the resulting count value (of items actually added) from Redis.
  def add_set(key, args)
puts "sendmessage calling: redis.sadd #{key}, *#{args}"
    redis.sadd key, *args
  end

  # Add, with 'key', the specified set with items 'args'.  If the set
  # (with 'key') already exists, remove the old set first before creating
  # the new one.
  # Return the resulting count value (of items actually added) from Redis.
  def replace_set(key, args)
puts "sendmessage calling: redis.del #{key}"
    redis.del key
puts "sendmessage calling: redis.sadd #{key}, *#{args}"
    redis.sadd key, *args
  end

  # Remove members 'args' from the set specified by 'key'.
  def remove_from_set(key, args)
    redis.srem key, *args
  end

  # Delete the object (message inserted via 'set_message', set added via
  # 'add_set', or etc.) with the specified key.
  def delete_object(key)
puts "sendmessage calling: redis.del #{key}"
    redis.del key
  end

end
