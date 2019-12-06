# Messages that have been (or will be[??!!!]) logged to the MessageLog
#!!!!This class is not finished, not currently used (Oct 22, 2019), and is
#!!!!probably not needed.  If it's not needed, remove it soon!!!!!!
module LoggedMessage
  include Contracts::DSL

  public

  #####  Access

  # The "key" used to access (when reading) or mark (when writing) the
  # desired log contents
  post :exists do |result| result != nil end
  post :size   do |result| result.respond_to?(:size) && result.size > 0 end
  def key
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The entire log contents (associated with 'key') - if 'count' != nil, it
  # will be used as a limit for the number of entries returned; otherwise,
  # there is no size limit for the result.
  post :result do |result| result != nil && result.is_a?(Array) end
  def contents(count: nil)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Basic operations

  # Send the specified tag: msg pair to the log.
  pre :good_args do |tag, msg| ! (tag.nil? || msg.nil?) end
  def send_message(tag, msg)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Send 'messages_hash' (hash table with {tag: msg} pairs) to the log.
  pre :mhash_good do |mhash| mhash != nil && mhash.is_a?(Hash) end
  def send_messages(messages_hash)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Send 'messages_hash' (hash table with {tag: msg} pairs), with the key
  # 'a_key' (instead of self.key) to the log.
  pre :key_good do |k| k != nil end
  pre :mhash_good do |k, mhash| mhash != nil && mhash.is_a?(Hash) end
  def send_messages_with_key(a_key, messages_hash)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  State-changing operations

  # Change the logging 'key' to 'new_key'.
  pre  :good_key do |new_key| new_key != nil && new_key.size > 0 end
  post :key_set  do |new_key| key == new_key end
  def change_key(new_key)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

end
