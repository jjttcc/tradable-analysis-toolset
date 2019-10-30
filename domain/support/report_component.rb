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

  # Message labels - one per message
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  def labels
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The contents of the report - i.e., one message per label
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  def messages
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The "type" of this report component, to be seen by the user
  def component_type
    COMPONENT_TYPE
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
