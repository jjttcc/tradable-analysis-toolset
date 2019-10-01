# Abstract interface for log access functionality
module LogReader
  include Contracts::DSL

  public

  #####  Access

  # The entire log contents for 'key' - if 'count' != nil, it will be used
  # as a limit for the number of entries returned; otherwise, there is no
  # size limit for the result.
  pre  :args_hash  do |hash| hash.respond_to?(:to_hash) end
  pre  :key_exists do |hash| hash.has_key?(:key) && hash[:key] != nil end
  post :result do |res| res != nil && res.is_a?(Array) end
  def contents(key:, count: nil)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The log contents for the specified 'key_list'.
  # If 'count' != nil, it will be used as a limit for the number of entries
  # retrieved per key; otherwise, there is no limit.
  # If 'block_msecs' != nil the operation will block, if needed, for the
  # specified number of milliseconds, to wait for input.
  # If 'new_only' is true, only "new" (i.e., anything that arrives after
  # this method invocation[!!!check!!!]) content will be returned.
  pre  :args_hash  do |hash| hash.respond_to?(:to_hash) end
#  pre  :blsecs_natural do |hash| implies(hash[:block_msecs] != nil,
#        hash[:block_msecs].is_a?(Numeric) && hash[:block_msecs] >= 0) end
  post :hash_result do |r| r != nil && r.is_a?(Hash) end
  def contents_for(key_list:, count: nil, block_msecs: nil, new_only: false)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

end
