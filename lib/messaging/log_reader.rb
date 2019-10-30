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
  pre :args_hash do |args_hash| args_hash != nil && args_hash.is_a?(Hash) end
  pre :has_keylist do |args_hash| args_hash.has_key?(:key_list) end
  pre :valid_keys do |args_hash| args_hash[:key_list].is_a?(Enumerable) ||
    args_hash[:key_list].respond_to?(:to_sym) end
  def trim_contents(args_hash)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

=begin
####!!!!!obsolete - remove this:
  # The object stored with 'key' - nil if there is not object at 'key'
  pre  :args_hash  do |hash| hash.respond_to?(:to_hash) end
  pre  :key_exists do |hash| hash.has_key?(:key) && hash[:key] != nil end
  def object(key:)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end
=end

end
