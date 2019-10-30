require 'report_component'

# Reports on a specific "topic" - e.g., a particular service
class TopicReport
  include Contracts::DSL, Enumerable

  public

  #####  Access

  # topic label (or "handle")
  def label
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  alias_method :handle, :label

  # Date/time of the earliest report
  post :nil_if_empty do |res| implies(empty?, res.nil?) end
  def start_date_time
    result = nil
    if ! empty? then
      result = first.datetime
    end
    result
  end

  # Date/time of the latest report
  post :nil_if_empty do |res| implies(empty?, res.nil?) end
  def end_date_time
    result = nil
    if ! empty? then
      result = last.datetime
    end
    result
  end

  # Summary of report contents
  def summary
    result = "label: #{label}, number of components: #{count}\n" +
      "date/time of first component: #{start_date_time}\n" +
      "date/time of last component:  #{end_date_time}"
    result
  end

  # First report (chronologically)
  pre  :not_empty do count > 0 end
  post :component do |reslt| reslt != nil && reslt.is_a?(ReportComponent) end
  def first
    self[0]
  end

  # Last report (chronologically)
  pre  :not_empty do count > 0 end
  post :component do |reslt| reslt != nil && reslt.is_a?(ReportComponent) end
  def last
    self[-1]
  end

  pre  :not_empty do count > 0 end
  pre  :in_range do |i| i == -1 || (i >= 0 && i < count) end
  post :component do |res| res != nil && res.is_a?(ReportComponent) end
  def [](index)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The "type" of this report, to be seen by the user
  def component_type
    COMPONENT_TYPE
  end

  #####  Boolean queries

  post :true_iff_0_count do |result| result == (count == 0) end
  def empty?
    count == 0
  end

  def ===(other)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Measurement

  # Number of contained "ReportComponent"s
  post :natural do |result| result != nil && result >= 0 end
  def count
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Total number of messages in all contained "ReportComponent"s
  post :natural do |result| result != nil && result >= 0 end
  def total_message_count
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Iteration

  def each(&block)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  protected

  COMPONENT_TYPE = "topic"

end
