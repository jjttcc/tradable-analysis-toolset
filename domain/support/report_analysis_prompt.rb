require 'tty-prompt'
require 'tty-pager'
require 'local_time'

# Facilities for extracting information, based on requests obtained from
# the user (via the TTY::Prompt tool), from a report (which is de-serialized
# from the provided open file)
class ReportAnalysisPrompt
  include Contracts::DSL, LocalTime, ReportTools, TatUtil

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
      { key: 'a', name: 'select All components for inspection',
          value: self.method(:inspect_all_components) },
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
      { key: 'a', name: 'select All components for inspection',
          value: self.method(:inspect_all_components) },
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
  BORDER = "#{"=" * 76}\n"

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

  begin

  CASE_SWITCH, HELP_SWITCH, KEYS_SWITCH, VALUES_SWITCH, KVBOTH_SWITCH =
    '{c}', '{h}', '{k}', '{v}', '{b}'
  KEYS_NAME, VALUES_NAME, BOTH_NAME =
    "keys-only", "values-only", "keys-and-values"

  def grep_mode_name(keys_bool, values_bool)
    if keys_bool then
      result = (values_bool)? BOTH_NAME: KEYS_NAME
    else
      check(! (! keys_bool && ! values_bool),
            "not valid: keys == false && values == false")
      result = VALUES_NAME
    end
  end

  def grep_switch_help
    "Enter {<letter>} to execute a command or change an option, where <letter>
is one of:
    h  - display this Help
    c  - toogle Case sensitivity
    k  - search Keys (labels) only
    v  - search Values (message bodies) only
    b  - search Both keys and values

For example, enter (without quotes): '{k}' for search-only-keys mode"
  end

  # Obtain a pattern from the user, fetch the report-components that match
  # the pattern, and allow the user to inspect the results.
  def grep(r)
    finished, strict_case, keys, values = false, false, true, true
    prompt = TTY::Prompt.new
    while not finished do
      q = "\n(Case sensitivity is #{(strict_case)? "on": "off"}. " +
      q = "Search mode is '#{grep_mode_name(keys, values)}')\n" +
        "(Hit <Enter> to exit this menu.)\n" +
        "Enter regular expression pattern (or \"#{HELP_SWITCH}\" to for help) "
      print q
      response = prompt.ask("")
      case response
      when nil then
        finished = true
      when HELP_SWITCH then
        puts grep_switch_help
      when CASE_SWITCH then
        strict_case = ! strict_case
      when KEYS_SWITCH then
        keys = true; values = false
      when VALUES_SWITCH then
        keys = false; values = true
      when KVBOTH_SWITCH then
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
    end
  end

  # Fetch all report-components accessible via 'r' and allow the user to
  # inspect the results.
  def inspect_all_components(r)
    prompt = TTY::Prompt.new
    matches = r.matches_for(:all)
    if matches.empty? then
      puts "No components found for '#{r}'\n"
    else
      display_matches(matches)
    end
=begin
    while not finished do
      q = "\n(Case sensitivity is #{(strict_case)? "on": "off"}. " +
      q = "Search mode is '#{grep_mode_name(keys, values)}')\n" +
        "(Hit <Enter> to exit this menu.)\n" +
        "Enter regular expression pattern (or \"#{HELP_SWITCH}\" to for help) "
      print q
      response = prompt.ask("")
      case response
      when nil then
        finished = true
      when HELP_SWITCH then
        puts grep_switch_help
      when CASE_SWITCH then
        strict_case = ! strict_case
      when KEYS_SWITCH then
        keys = true; values = false
      when VALUES_SWITCH then
        keys = false; values = true
      when KVBOTH_SWITCH then
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
    choices = {}
    i = 1
    tr.message_labels.each do |l|
      choices[i.to_s] = {name: l, value: tr.messages_for(l)}
      i += 1
    end
    choices['b'] = {name: 'back', value: false}
    choices['q'] = {name: 'quit', value: nil}
    display = BORDER
    choices.keys.each do |k|
      display += "#{k}: #{choices[k][:name]}\n"
    end
    while not finished do
      if $stdout.isatty then
        pager = TTY::Pager.new
        pager.page(display)
      else
        puts display
      end
      response = prompt.ask("Choose label or action")
      choice = choices[response]
      if choice.nil? then
        puts "\nInvalid choice - try again."
      else
        value = choice[:value]
        if value.nil? then
          exit 0
        elsif value then
          display_messages(value)
        else
          finished = true
        end
      end
    end
  end

  def inspect_label_work2(tr)
#!!!!We appear to need the option to include dates/timestamps!!!!!!!!!!!
    finished = false
    prompt = TTY::Prompt.new
    choices = {}
    i = 1
    tr.message_labels.each do |l|
      choices[i.to_s] = {name: l, value: tr.messages_for(l)}
      i += 1
    end
    choices['b'] = {name: 'back', value: false}
    choices['h'] = {name: 'help', value: :help}
    choices['q'] = {name: 'quit', value: nil}
    display = ""
#!!!    choices.each { |c| display += "#{choices[:key]}: #{choices[:name]}\n" }
    choices.keys.each do |k|
#      display += "#{choices[:key]}: #{choices[:name]}\n"
      display += "#{k}: #{choices[k][:name]}\n"
    end

    while not finished do
      if $stdout.isatty then
        pager = TTY::Pager.new
        pager.page(display)
      else
        puts display
      end
      response = prompt.ask("Choose label or action")
      choice = choices[response][:value]
      if response == 'b' then
        finished = true
      elsif response == 'q' then
        exit 0
      elsif response == 'h' then
        puts "Help!"
      else
        if is_i?(response) then
          n = response.to_i
          choice = matches[n]
          if choice != nil then
            inspect_selected_matches(choices)
          else
            ###!!!!Handle invalid choice
          end
        else
          puts "Your response is not a number (#{response}) - try again" +
            "\n(Empty response exits this menu.)"
        end
      end
    end
  end

  def inspect_label_work1(tr)
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
    display = ""
    choices.each { |c| display += "#{choices[:key]}: #{choices[:name]}\n" }

    while not finished do
      if $stdout.isatty then
        pager = TTY::Pager.new
        pager.page(display)
      else
        puts display
      end
      response = prompt.ask("Choose label or action") do |r|
        r.in(['b', 'q', 'h', "1-#{choices.count - 3}"])
      end
      if response == 'b' then
        finished = true
      elsif response == 'q' then
        exit 0
      elsif response == 'h' then
        puts "Help!"
      else
        if is_i?(response) then
          n = response.to_i
          choice = matches[n]
          if choice != nil then
            inspect_selected_matches(choices)
          else
            ###!!!!Handle invalid choice
          end
        else
          puts "Your response is not a number (#{response}) - try again" +
            "\n(Empty response exits this menu.)"
        end
      end
    end
=begin
if choice.nil? then
  exit 0
elsif choice then
  display_messages(choice)
else
  finished = true
end
=end
  end

  def old___inspect_label(tr)
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
#!!!!Fix bug: Use something other than expand to get rid of:
#    "Choice key `10` is more than one character long."
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
    display = BORDER + messages.join("\n")
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

#=begin
#  # Display 'grep' results
#  def old___display_matches(matches, pattern)
#    display = "#{matches.count} matching components found for '#{pattern}':\n"
#    i = 1
#    matches.each do |m|
#      display += "#{i}: #{formatted_local_time(m.datetime)}, count: " +
#        "#{m.count}, first: #{m.matches.first}\n"
#      i += 1
#    end
#    inspect_matches(matches, display)
#  end
#=end

  # Display 'grep' results
  def display_matches(matches, pattern = nil)
    choices = {}
    i = 1
    matches.each do |m|
      choices[i.to_s] = {name: "#{formatted_local_time(m.datetime)}, " +
        "count: #{m.count}, first: #{m.matches.first}\n",
                         value: m}
      i += 1
    end
    choices['b'] = {name: 'back', value: false}
    choices['q'] = {name: 'quit', value: nil}
    display = BORDER +
      "#{matches.count} matching components found" + ((pattern.nil?)? ":\n":
          " for '#{pattern}':\n")
    choices.keys.each do |k|
      display += "#{k}: #{choices[k][:name]}\n"
    end
    inspect_choices(choices, display, matches.count)
  end

  # Inspect the specified (search) "matches".
  def inspect_choices(choices, display_str, max_index)
    finished = false
    while not finished do
      begin
        prompt = TTY::Prompt.new
        if $stdout.isatty then
          begin
            pager = TTY::Pager.new
            pager.page(display_str)
          rescue Errno::EPIPE => e
            # (User hit 'q' to stop pager - assume she wants to continue.)
            #!!!          inspect_selected_matches(values)
          end
        else
          puts display_str
        end
        puts "B"
        response = prompt.ask("> [b, q, 1..#{max_index}]")
        puts "C"
        keys = keys_from_user_list(response: response, int_max: max_index,
                 allowed_non_ints: ['q', 'b'], nil_choice: 'b')
        puts "D"
        values = keys.map do |k|
          v = choices[k][:value]
          if v.nil? then
            exit 0            # User ordered "quit"   (Ignore other choices.)
          elsif v == false then
            finished = true   # User requested "back" (Ignore other choices.)
            break
          end
          v
        end
        puts "E"
        if ! finished then
          puts "F"
          inspect_selected_matches(values)
        end
      rescue RuntimeError => e
        r = prompt.ask("#{e} - Try again? ")
        if r =~ /^n/i then
          exit 0
        end
      end
    end
  end

  # Array of keys (strings) "extracted" from a user-supplied response
  # 'int_min' is the lowest allowed integer value and 'int_max' is the
  # highest allowed integer value. 'allowed_non_ints' is an array
  # specifying all allowed non-integer responses.  If 'nil_choice' is not
  # nil, it indicates the choice to assume if response.nil? (i.e., the
  # result is simply [nil_choice]); if 'nil_choice' is nil and 'response'
  # is nil, an exception is raised (i.e., indicating an invalid response).
  pre  :ani_array do |hash| implies(hash[:allowed_non_ints] != nil,
                              hash[:allowed_non_ints].is_a?(Array)) end
  post :array do |result| result != nil && result.is_a?(Array) end
  def keys_from_user_list(response:, int_min: 1, int_max:,
                          allowed_non_ints: nil, nil_choice: nil)
    if response.nil? then
      if nil_choice.nil? then
        raise "Invalid (null/empty) response"
      else
        result = [nil_choice]
      end
    else
      range_error = false
      if response =~ /-/ then
        lower, upper = response.split(/\s*-\s*/, 2)
        if is_i?(lower) && is_i?(upper) then
          result = (lower .. upper).to_a
puts "l, u: #{lower}, #{upper}"
puts "mi, mx: #{int_min}, #{int_max}"
          range_error = lower.to_i < int_min || upper.to_i > int_max
        else
          range_error = true
        end
        if range_error then
          raise "Invalid range specified: #{response} (" +
          "expected #{int_min}..#{int_max})"
        end
      else
        result = response.split(/,\s*/, 10000)
        result.each do |e|
          if is_i?(e) then
            i = e.to_i
            if i < int_min || i > int_max then
              raise "Number selection (#{e}) out of range [" +
                "#{int_min}..#{int_max}]"
            end
          elsif ! allowed_non_ints.include?(e) then
            raise "Invalid character or string: #{e}"
          end
        end
      end
    end
puts "kful result: #{result.inspect}"
    result
  end

#=begin
#  # Inspect the specified (search) "matches".
#  def old___inspect_matches(matches, display_str)
#    finished = false
#    display_str = "#{"=" * 72}\n" +
#      "Choose the number of the item you would like to inspect.\n" +
#      display_str
#    while not finished do
#      if $stdout.isatty then
#        pager = TTY::Pager.new
#        pager.page(display_str)
#      else
#        puts display_str
#      end
#      prompt = TTY::Prompt.new
#      response = prompt.ask("> ")
#      if response.nil? then
#        finished = true
#      else
#        if is_i?(response) then
#          n = response.to_i
#          choice = matches[n]
#          if choice != nil then
#            inspect_selected_matches(choices)
#          else
#            ###!!!!Handle invalid choice
#          end
#        else
#          puts "Your response is not a number (#{response}) - try again" +
#            "\n(Empty response exits this menu.)"
#        end
#      end
#    end
#  rescue Errno::EPIPE => e
#  end
#=end

  def inspect_selected_matches(matches)
#puts "You have a #{matches.class} on your hands " +
#  "(size: #{matches.count}, contents:\n#{matches.inspect})"
    finished = false
    display = BORDER
    matches.each do |match|
      display += "match count for #{match.id}: #{match.count}\n" +
      "time stamp: #{match.datetime}\nMESSAGES:\n"
      match.matches.each do |k, v|
        display += "#{k}:  #{v}\n"
      end
      display += "#{"-" * 62}\n"
    end
    while not finished do
      if $stdout.isatty then
        pager = TTY::Pager.new
        pager.page(display)
      else
        puts display
      end
      prompt = TTY::Prompt.new
      response = prompt.ask("View again?")
      if response.nil? || response =~ /\bn/i then
        finished = true
      end
    end
  end

#=begin
#  def old___inspect_selected_matches(choice)
## 'matches':  Hash table containing the matching messages for which, for each
## 'owner':    The ReportComponent that owns the matches
## 'datetime': owner.datetime
## 'id':       owner.id
## 'count':    matches.count
#    finished = false
#    while not finished do
#      display = BORDER + "match count for #{choice.id}: #{choice.count}\n" +
#        "time stamp: #{choice.datetime}\nMESSAGES:\n"
#      choice.matches.each do |k, v|
#        display += "#{k}:  #{v}\n"
#      end
#      if $stdout.isatty then
#        pager = TTY::Pager.new
#        pager.page(display)
#      else
#        puts display
#      end
#      prompt = TTY::Prompt.new
#      response = prompt.ask("View again?")
#      if response.nil? || response =~ /\bn/i then
#        finished = true
#      end
#    end
#  end
#=end

end
