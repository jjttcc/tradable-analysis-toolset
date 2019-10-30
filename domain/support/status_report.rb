require 'time_util'
require 'topic_report'

# Reports on the status of the system, services, etc. - consisting of
# "TopicReport"s
class StatusReport
  include Contracts::DSL, Enumerable

  public

  #####  Access

  # The date & time, in seconds, the report was created (Unix timestamp - i.e.,
  # seconds since the "epoch")
  post :natural do |result| result != nil && result >= 0 end
  def timestamp
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The date & time the report was created as a DateTime
  post :natural do |result| result != nil && result >= 0 end
  def date_time
    DateTime.strptime(timestamp.to_s, "%s")
  end

  # Enumerable contents - i.e., 0 or more of TopicReport
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  post :counts_match do |result| result.count == self.count end
  def topic_reports
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The label for each element (TopicReport) of 'topic_reports'
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  def labels
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The topic report for 'label'
  pre  :label do |label| label != nil end
  post :topic do |result| implies(result != nil, result.is_a?(TopicReport)) end
  def [](label)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The topic report for 'label'
  pre  :label do |label| label != nil end
  post :topic do |result| implies(result != nil, result.is_a?(TopicReport)) end
  def report_for(label)
    self[label]
  end

  # The "type" of this report, to be seen by the user
  def component_type
    COMPONENT_TYPE
  end

  # Summary of report contents
  def summary
    result = "Number of sub-reports: #{count}, date/time: #{date_time}\n" +
      "labels: #{labels.join(", ")}\n"
    subcount = sub_counts.inject(0){|sum,x| sum + x }
    result += "subcount: #{subcount}\n"
    result
  end

  #####  Boolean queries

  def ===(other)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Measurement

  # Array: count of each of 'topic_reports'
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  def sub_counts
    topic_reports.each.map { |r| r.count }
  end

  #####  Iteration

  def each(&block)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  protected

  COMPONENT_TYPE = "status"

end
