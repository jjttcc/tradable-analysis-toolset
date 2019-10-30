require 'time_util'
require 'status_report'
require 'redis_topic_report'

# Status reports built with Redis stream-based data structures
class RedisStatusReport < StatusReport
  include Contracts::DSL

  public

  #####  Access

  attr_reader :timestamp, :contents

  def topic_reports
    contents.values
  end

  def labels
    contents.keys
  end

  pre  :label do |label| label != nil end
  post :topic do |result| result != nil && result.is_a?(TopicReport) end
  def [](label)
    result = contents[label]
    result
  end

  alias_method :report_for, :[]

  def what_the___summary
    result = "Number of items: #{contents.count}\n"
    result += "timestamp, contents.type: #{timestamp}, #{contents.class}\n"
    if contents.count > 0 then
      first = contents.first
      result += "first.count: #{first.count}\n"
      result += "type of first: #{first.class}\n"
      if first.count > 0 then
        ffirst = first.first
        fsecond = first[1]
        result += "type of first of first: #{ffirst.class}\n"
        result += "type of second of first: #{fsecond.class}\n"
        result += "second of first (topic report): #{fsecond}\n"
        result += "1st of 2nd of 1st: #{fsecond.first}\n"
        result += "1st of 2nd of 1st.inspect: #{fsecond.first.inspect}\n"
        result += "1st of 2nd of 1st timestamp: #{fsecond.first.timestamp}\n"
        result += "1st of 2nd of 1st datetime: #{fsecond.first.datetime}\n"
      end
    end
    result
  end

  #####  Boolean queries

  def ===(other)
    other != nil && contents == other.contents &&
      timestamp == other.timestamp
  end

  #####  Measurement

  # Number of TopicReports
  def count
    contents.count
  end

  #####  Iteration

  def each(&block)
    contents.keys.each do |k|
      block.call(self[k])
    end
  end

  #####  Invariant

  def invariant
    contents != nil
  end

  private

  pre  :guts do |guts| guts != nil && guts.is_a?(Hash) end
  post :timestamp do self.timestamp != nil end
  post :invariant do invariant end
  post :contents_hash do self.contents.is_a?(Hash) end
  def initialize(guts)
    @timestamp = TimeUtil::current_date_time.to_i
    @contents = Hash[guts.keys.collect do |k|
      [k, RedisTopicReport.new(label: k, guts: guts[k])]
    end]
  end

end
