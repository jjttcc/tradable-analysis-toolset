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
      { key: 'g', name: 'search/Grep for pattern', value: self.method(:grep) },
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
      { key: 'g', name: 'search/Grep for pattern', value: self.method(:grep) },
      { key: 'l', name: 'unique message Labels',
          value: self.method(:tr_labels) },
      { key: 'i', name: 'Inspect message label',
          value: self.method(:inspect_label)},
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

  def grep_switch_help
"Something goes here..."
  end

  # Obtain a pattern from the user, fetch the report-components that match
  # the pattern, and ...
  def grep(r)
    finished, strict_case, keys, values = false, false, true, true
    case_switch, help_switch, keys_switch, values_switch, kvboth_switch =
      '{c}', '{h}', '{k}', '{v}', '{b}'
    prompt = TTY::Prompt.new(track_history: false)
    while not finished do
      q = "\n(Case sensitivity is #{(strict_case)? "on": "off"}) " +
        "(Hit <Enter> to exit this menu.)\n" +
        "Enter regular expression pattern (or #{help_switch} to switch " +
        "case sensitivity) "
      print q
      response = prompt.ask("")
      case response
      when nil then
        finished = true
      when help_switch then
        puts grep_switch_help
      when case_switch then
        strict_case = ! strict_case
      when keys_switch then
        keys = true; values = false
      when values_switch then
        keys = false; values = true
      when kvboth_switch then
        keys = true; values = true
      else
        options = (strict_case)? nil: Regexp::IGNORECASE
        matches = r.matches_for(Regexp.new(response, options),
                               use_keys: keys, use_values: values)
        if matches.empty? then
          puts "No matches found for '#{response}'\n"
        else
          display_matches(matches, response)
        end
      end
=begin
      if response.nil? then
        finished = true
      elsif response == case_switch then
        strict_case = ! strict_case
      else
        options = (strict_case)? nil: Regexp::IGNORECASE
        matches = r.matches_for(Regexp.new(response, options),
                               use_keys: keys, use_values: values)
        if matches.empty? then
          puts "No matches found for '#{response}'\n"
        else
          display_matches(matches, response)
        end
      end
=end
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
    puts tr.summary(
      lambda do |datetime|
        local_time(datetime).strftime(DATEFMT)
      end
    )
  end

  def tr_labels(tr)
    puts tr.message_labels.join(", ")
  end

  def tr_detailed_summary(tr)
    summ = count_summary(report: tr, label: "Element counts")
    if $stdout.isatty then
      pager = TTY::Pager.new
      pager.page(summ)
    else
      puts summ
    end
  end

  def inspect_label(tr)
#!!!!We appear to need the option to include dates/timestamps!!!!!!!!!!!
    finished = false
    prompt = TTY::Prompt.new
    choices = []
    i = 1
    tr.message_labels.each do |l|
      choices <<
      { key: i.to_s, name: l, value: tr.messages_for(l) }
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
        display_messages(choice)
      else
        finished = true
      end
    end
  end

  # Inspect the specified (search) "matches".
  def inspect_selected(matches, display_list)
    if $stdout.isatty then
      pager = TTY::Pager.new
      pager.page(display_list)
    else
      puts display_list
    end
  rescue Errno::EPIPE => e
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

  #####  Utilities

  def display_messages(messages)
    border = "#{"=" * 72}\n"
    display = border + messages.join("\n")
    if $stdout.isatty then
      pager = TTY::Pager.new
      pager.page(display)
    else
      puts display
    end
  end

  def formatted_local_time(dt)
    local_time(dt).strftime(DATEFMT)
  end

  # Display 'grep' results
  def display_matches(matches, pattern)
    border = "#{"=" * 72}\n"
    display = border +
      "#{matches.count} matching components found for '#{pattern}':\n"
    i = 1
    matches.each do |m|
      display += "#{i}: #{formatted_local_time(m.datetime)}, count: " +
        "#{m.count}, first: #{m.matches.first}\n"
      i += 1
    end
    inspect_selected(matches, display)
  end

end
