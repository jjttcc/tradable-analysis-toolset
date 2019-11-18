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

  # The log contents for the specified args_hash[:key_list]
  # Other specifications or options may be present in 'args_hash' depending
  # on the run-time type of the LogReader object (i.e., the class that
  # includes LogReader that is used to instantiate this object)
  pre  :args_hash do |hash| hash != nil && hash.respond_to?(:to_hash) end
  pre  :has_keylist do |hash| hash.has_key?(:key_list) end
  post :hash_result do |r| r != nil && r.is_a?(Hash) end
  def contents_for(args_hash)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Measurement

  # The count - number of elements - for each key specified via
  # args_hash[:key_list] - parallels 'contents_for', with the difference
  # that instead of returning the contents for each specified key, the
  # result is simply the count for each specified key
  # (Any other keys/options in 'args_hash' will be ignored.)
  pre  :args_hash do |hash| hash != nil && hash.respond_to?(:to_hash) end
  pre  :has_keylist do |hash| hash.has_key?(:key_list) end
  post :hash_result do |r| r != nil && r.is_a?(Array) end
  def counts_for(args_hash)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Removal

  # Delete all contents associated with the specified key list.
  pre :key_list do |hash| hash != nil && hash[:key_list] != nil end
  pre :valid_keys do |hash| hash[:key_list].is_a?(Enumerable) ||
    hash[:key_list].respond_to?(:to_sym) end
  def delete_contents(key_list:)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Trim contents associated with the specified keys (args_hash[:key_list]),
  # according to the other options/arguments contained in 'args_hash' and
  # the semantics implemented via the run-time type of 'self'.
  pre :args_hash do |args| args != nil && args.respond_to?(:to_hash) end
  pre :has_keylist do |args| args.has_key?(:key_list) end
  pre :valid_keys do |args| args[:key_list].is_a?(Enumerable) ||
    args[:key_list].respond_to?(:to_sym) end
  def trim_contents(args_hash)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

end
