# !!!!!TO-DO: Move this class to its own file!!!!:
# Matching results from a search of ReportComponent objects
# 'matches':  Hash table containing the matching messages for which, for each
#             element, the key is the message label and the value is the
#             message body
# 'owner':    The ReportComponent that owns the matches
# 'datetime': owner.datetime
# 'id':       owner.id
# 'count':    matches.count
ReportMatchResult = Struct.new(:matches, :owner) do
  def datetime
    owner.datetime
  end
  def id
    owner.id
  end
  def count
    matches.count
  end
end

# Components, or elements, of a report, consiting of a timestamp and 0 or
# more labeled messages.
class ReportComponent
  include Contracts::DSL

  public

  #####  Access

  def id
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  alias_method :handle, :id

  # Unix timestamp associated with the component (milliseconds since the epoch)
  post :natural do |result| result != nil && result >= 0 end
  def timestamp
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Date & time associated with 'timestamp'
  post :exists do |result| result != nil end
  def datetime
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Message labels, one per message (i.e., in the same order as 'messages')
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  def labels
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The contents of the report - i.e., one message per label
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  def messages
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The message for the specified 'label' (nil if 'label' is not present)
  def message_for(label)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # !!!!Describe me, please!!!!!
  pre  :regex do |p| p != nil && p.is_a?(Regexp) end
  post :result_exists do |result| result != nil end
  post :result_format do |result| result.respond_to?(:id) &&
    result.respond_to?(:datetime) && result.respond_to?(:matches) &&
    result.respond_to?(:count) end
  def matches_for(pattern, use_keys: true, use_values: true)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The "type" of this report component, to be seen by the user
  def component_type
    COMPONENT_TYPE
  end

  def to_s
    "handle: #{handle}, #{messages.count} messages"
  end

  #####  Boolean queries

  def ===(other)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Measurement

  # Count of 'messages'
  post :msgs_count do |result| result == self.messages.count end
  def message_count
    messages.count
  end

  alias_method :count, :message_count

  protected

  COMPONENT_TYPE = "topic report component"

end
