require 'tty-prompt'
require 'tty-pager'
require 'local_time'

# Facilities for extracting information, based on requests obtained from
# the user (via the TTY::Prompt tool), from a report (which is de-serialized
# from the provided open file)
class ReportAnalysisPrompt
  include Contracts::DSL, LocalTime, ReportTools

  public

  #####  Access

  attr_reader :input_file, :report

  # Start the status-report interactive menu.
  def start_status
    prompt = TTY::Prompt.new
    choices = [
      { key: 's', name: 'Summary', value: self.method(:summary) },
      { key: 'd', name: 'Date range', value: self.method(:date_ranges) },
      { key: 'c', name: 'Counts', value: self.method(:counts) },
      { key: 't', name: 'sTatistics', value: self.method(:stats) },
      { key: 'e', name: 'dEtailed summary',
          value: self.method(:tr_detailed_summary) },
      { key: 'r', name: 'choose sub-Report', value: self.method(:sub_report)},
      { key: 'q', name: 'Quit: terminate analysis', value: lambda { exit 0 } },
    ]
    while true do
      choice = prompt.expand('Choose analysis action ', choices)
      choice.call(report)
    end
  end

  # Start the topic-report interactive menu.
  def start_topic(tr)
    prompt = TTY::Prompt.new
    choices = [
      { key: 's', name: 'Summary', value: self.method(:tr_summary) },
      { key: 'd', name: 'Dates', value: self.method(:tr_dates) },
      { key: 'c', name: 'Count', value: self.method(:tr_count) },
      { key: 't', name: 'sTatistics', value: self.method(:tr_stats) },
      { key: 'e', name: 'dEtailed summary',
          value: self.method(:tr_detailed_summary) },
      { key: 'b', name: 'exit sub-menu (Back)', value: false },
      { key: 'q', name: 'Quit: terminate analysis', value: lambda { exit 0 } },
      { key: 'u', name: 'debUg', value: self.method(:tr_debug) },
    ]
    choice = prompt.expand('Choose analysis action ', choices)
    while choice do
      choice.call(tr)
      choice = prompt.expand('Choose analysis action ', choices)
    end
  end

  private

  DATEFMT = '%Y-%m-%d %H:%M:%S'

  attr_reader :config

  pre  :infile do |infile| infile != nil && ! infile.closed? end
  pre  :config do |cfg| cfg != nil end
  post :infile_set do |res, ifn, cfg| self.input_file == ifn end
  post :config_set do |res, ifn, cfg| @config == cfg end
  def initialize(infile, cfg)
    @config = cfg
    @input_file = infile
    de_serializer = config.de_serializer.new(self.input_file.read)
    @report = de_serializer.result
  end

  #####  Method choices

  def summary(r)
    puts "summary: #{r.summary}"
  end

  # Print the start- and end-date of each topic-report in 'r'
  def date_ranges(r)
    r.topic_reports.each do |tr|
      tag = tr.label + ":"
      start_dt = local_time(tr.start_date_time)
      end_dt = local_time(tr.end_date_time)
      puts sprintf("%-26s %s, %s", tag,
                   start_dt.strftime(DATEFMT), end_dt.strftime(DATEFMT))
    end
  end

  # Print the number of topic-reports in 'r'
  def count(r)
    puts "count: #{r.count}"
  end

  # Print the number of topic-reports in 'r' and the number of components for
  # each of those topic-reports
  def counts(r)
    puts "#{r.component_type} count: #{r.count}"
    if r.topic_reports.count > 0 then
      puts "#{r.topic_reports[0].component_type} counts: " +
        "#{r.sub_counts.join(", ")}"
    else
      puts "0 sub-reports"
    end
  end

  # Print stats for 'r'.  - To-be-refined/changed/fixed/...
  def stats(r)
    puts "#{r.component_type} count: #{r.count}"
    if r.topic_reports.count > 0 then
      puts "#{r.topic_reports[0].component_type} counts: " +
        "#{r.sub_counts.join(", ")}"
    else
      puts "0 sub-reports"
    end
  end

  def sub_report(r)
    finished = false
    prompt = TTY::Prompt.new
    choices = []
    i = 1
    r.labels.each do |l|
      choices <<
      { key: i.to_s, name: l, value: r.report_for(l) }
      i += 1
    end
    choices << { key: 'b', name: 'back', value: false }
    i += 1
    choices << { key: 'q', name: 'quit', value: nil }
    while ! finished do
      choice = prompt.expand('Choose analysis action ', choices)
      if choice.nil? then
        exit 0
      elsif choice then
        start_topic(choice)
      else
        finished = true
      end
    end
  end

  #####  Method choices for "TopicReport"s

  def tr_summary(tr)
    puts tr.summary
  end

  def tr_detailed_summary(tr)
    pager = TTY::Pager.new
    summ = count_summary(report: tr, label: "Element counts")
    if $stdout.isatty then
      pager.page(summ)
    else
      puts summ
    end
  end

  def tr_dates(tr)
    start_dt = local_time(tr.start_date_time)
    end_dt = local_time(tr.end_date_time)
    puts "#{tr.label}: #{start_dt.strftime(DATEFMT)}, " +
      "#{end_dt.strftime(DATEFMT)}"
  end

  def tr_count(tr)
    puts tr.count
  end

  def tr_stats(tr)
puts "tr_stats - work in progress {WPA}"
  end

  def tr_debug(tr)
    # Force 'tr' to load/instantiate each of its elements:
    tr.each do |t|
    end
    pp tr
  end

end
