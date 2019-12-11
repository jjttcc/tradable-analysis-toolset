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
      { key: 'c', name: 'report-category Counts',
        value: [self.method(:detailed_summary),
                [self.method(:count_summary)], 'Sub-report counts'] },
      { key: 'e', name: 'dEtailed summary',
        value: [self.method(:detailed_summary),
                [self.method(:status_info)], 'Details']},
      { key: 'g', name: 'search/Grep for pattern', value: self.method(:grep) },
      { key: 'a', name: 'select All components for inspection',
          value: self.method(:inspect_all_components) },
      { key: 'r', name: 'choose sub-Report', value: self.method(:sub_report)},
      { key: 'q', name: 'Quit: terminate analysis', value: lambda { exit 0 } },
    ]
    while true do
      choice = prompt.expand('Choose analysis action ', choices)
      routine, args = menu_components(report, choice)
      routine.call(*args)
    end
  end

  # Start the topic-report interactive menu.
  def start_topic(tr)
    prompt = TTY::Prompt.new
    choices = [
      { key: 's', name: 'Summary', value: self.method(:tr_summary) },
      { key: 'd', name: 'Dates', value: self.method(:tr_dates) },
      { key: 'c', name: 'Count', value: [self.method(:detailed_summary),
                                         [self.method(:count_summary)]] },
      { key: 'e', name: 'dEtailed summary', value:
        [self.method(:detailed_summary), [self.method(:count_summary),
                                        self.method(:topic_info)], 'Details'] },
      { key: 'g', name: 'search/Grep for pattern', value: self.method(:grep) },
      { key: 'a', name: 'select All components for inspection',
          value: self.method(:inspect_all_components) },
      { key: 'R', name:
        'select components in the specified date/time Range for inspection',
          value: self.method(:inspect_range) },
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
      routine, args = menu_components(tr, choice)
      routine.call(*args)
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
    puts "#{BORDER}#{r.summary}"
  end

  COL_SEP_MARGIN = 3
  def formatted_two_column_list(l, col1func, col2func, sep_str = ':')
    result = ""
    max_col_length = 0
    col1s, col2s = [], []
    l.each do |o|
      s = col1func.call(o)
      if s.length > max_col_length then
        max_col_length = s.length
      end
      col1s << s
      col2s << col2func.call(o)
    end
    sep_spaces = max_col_length + COL_SEP_MARGIN
    (0..col1s.count - 1).each do |i|
      result += sprintf("%-#{sep_spaces}s %s\n",
                        col1s[i] + sep_str, col2s[i])
    end
    result
  end

  # Print the start- and end-date of each topic-report in 'r'
  def date_ranges(r)
    label_func = lambda { |tr| tr.label }
    value_func = lambda do |tr|
      if tr.empty? then
        "empty"
      else
        "#{local_time(tr.start_date_time).strftime(DATEFMT)}, " +
          "#{local_time(tr.end_date_time).strftime(DATEFMT)}"
      end
    end
    puts "#{BORDER}" + formatted_two_column_list(r.topic_reports,
                                                 label_func, value_func)
  end

  # Print the number of topic-reports in 'r'
  def count(r)
    puts "count: #{r.count}"
  end

  # Print the number of topic-reports in 'r' and the number of components for
  # each of those topic-reports
  def counts(r)
    label_func = lambda { |tr| tr.label }
    value_func = lambda { |tr| number_with_delimiter(tr.count) }
    if r.topic_reports.count > 0 then
      puts BORDER + count_summary(report: r)
    else
      puts "0 sub-reports"
    end
  end

  begin

  CASE_SWITCH, HELP_SWITCH, KEYS_SWITCH, VALUES_SWITCH, KVBOTH_SWITCH,
    NEGATION_SWITCH = '{c}', '{h}', '{k}', '{v}', '{b}', '{n}'
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
    "Enter {<letter>} to execute a command or change an option, "\
      "where <letter>\nis one of:
    h  - display this Help
    c  - toogle Case sensitivity
    k  - search Keys (labels) only
    v  - search Values (message bodies) only
    b  - search Both keys and values
    n  - toggle Negation (don't-match/match pattern)

For example, enter (without quotes): '{k}' for search-only-keys mode"
  end

  # Obtain a pattern from the user, fetch the report-components that match
  # the pattern, and allow the user to inspect the results.
  def grep(r)
    finished, strict_case, keys, values = false, false, true, true
    negate = false
    prompt = TTY::Prompt.new
    last_response = ""
    while not finished do
      q = "\n(Case sensitivity is #{(strict_case)? "on": "off"}. " +
        "Search mode is '#{grep_mode_name(keys, values)}'. " +
        "Negation is '#{(negate)? "on": "off"}'.)\n" +
        "(Hit <Enter> to exit this menu.)\n" +
        "Enter regular expression pattern (or \"#{HELP_SWITCH}\" to for help) "
      if ! last_response.empty? then
        q += "[#{last_response}] "
      end
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
      when NEGATION_SWITCH then
        negate = ! negate
      else
        last_response = response
        options = (strict_case)? nil: Regexp::IGNORECASE
        matches = collected_matches(r, Regexp.new(response, options),
                                    keys, values, negate)
        if matches.empty? then
          puts "No matches found for '#{response}'\n"
        else
          display_matches(matches, response)
        end
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
  end

  # Fetch all report-components for 'r' according to a date/time range
  # specified by the user and allow the user to inspect the results.
  def inspect_range(r)
    puts "Count; and first and last dates of current data set:\n"\
      "#{r.count}; "\
      "#{local_time(r.first.datetime)}, #{local_time(r.last.datetime)}"
    prompt = TTY::Prompt.new
    abort_op = false
    finished = false
    while ! finished do
      start_time = prompted_datetime("start")
      end_time = prompted_datetime("end", false)
      matches = r.components_in_range(start_time, end_time)
      if matches.empty? then
        prompt_str = "No components found for '#{r.handle}'\n"
      else
        prompt_str = "#{matches.count} matches found\n"\
          "Date of earliest and latest matches:\n"\
          "#{local_time(matches.first.datetime)}, "\
          "#{local_time(matches.last.datetime)}\n"
      end
      choice = prompt.select(prompt_str, cycle: true) do |menu|
        menu.choice 'Continue?',     :continue
        menu.choice 'Try again?',    :again
        menu.choice 'Abort action?', :abort
      end
      finished = choice == :continue || choice == :abort
      abort_op = choice == :abort
    end
    if ! abort_op then
      print "Processing..."
      display_matches(matches)
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
    puts "#{BORDER}"
    puts tr.summary(
      lambda do |datetime|
        local_time(datetime).strftime(DATEFMT)
      end, 0, method(:number_with_delimiter)
    )
  end

  def tr_labels(tr)
    puts "#{BORDER}"
    puts wrap(tr.message_labels.join(", "), 79, '  ')
  end

  pre :args do |r, fp| r != nil && fp != nil end
  def detailed_summary(r, format_procs, label = nil)
    l = (label.nil?)? "": label
    if r.respond_to?(:label) then
      lbl = r.label
      if lbl != nil then
        l += " for #{lbl}"
      end
    end
    summary = BORDER
    format_procs.each do |p|
      summary += p.call(report: r, label: l)
    end
    if $stdout.isatty then
      pager = TTY::Pager.new
      pager.page(summary)
    else
      puts summary
    end
  end

  def inspect_label(tr)
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
        begin
          pager = TTY::Pager.new
          pager.page(display)
        rescue Errno::EPIPE => e
          # (User hit 'q' to stop pager - assume she wants to continue.)
        end
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

  def tr_dates(tr)
    start_dt = local_time(tr.start_date_time)
    end_dt = local_time(tr.end_date_time)
    puts "#{BORDER}#{tr.label}: #{start_dt.strftime(DATEFMT)}, " +
      "#{end_dt.strftime(DATEFMT)}"
  end

  def tr_count(tr)
    puts "#{BORDER}#{tr.count}"
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
      begin
        pager = TTY::Pager.new
        pager.page(display)
      rescue Errno::EPIPE => e
        # (User hit 'q' to stop pager - assume she wants to continue.)
      end
    else
      puts display
    end
  end

  def formatted_local_time(dt)
    local_time(dt).strftime(DATEFMT)
  end

  # Display 'grep' results
  def display_matches(matches, pattern = nil)
    choices = {}
    i = 1
    matches.each do |m|
      choices[i.to_s] = {name: "#{formatted_local_time(m.datetime)}, " +
        "count: #{m.count}, first: #{m.matches.first}",
                         value: m}
      i += 1
    end
    # Build the prompt and choices map for 'inspect_choices'.
    prompt = '['
    chars = %w/b q g/
    tables = [{name: 'back', value: false}, {name: 'quit', value: nil},
              {name: 'search/Grep', value: self.method(:grep)}]
    (0..2).each do |i|
      choices[chars[i]] = tables[i]
      if i > 0 then prompt += ", " end
      prompt += chars[i]
    end
    prompt += ", 1..#{matches.count}]"
    display = "\n" + BORDER +
      "#{matches.count} matching components found" + ((pattern.nil?)? ":\n":
          " for '#{pattern}':\n")
    choices.keys.each do |k|
      display += "#{k}: #{choices[k][:name]}\n"
    end
    inspect_choices(choices, display, matches.count, prompt)
  end

  # Inspect the specified (search) "matches".
  def inspect_choices(choices, display_str, max_index, prompt_str)
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
          end
        else
          puts display_str
        end
        response = prompt.ask("> #{prompt_str}")
        keys = keys_from_user_list(response: response, int_max: max_index,
                 allowed_non_ints: ['q', 'b', 'g'], nil_choice: 'b')
        values = keys.map do |k|
          v = choices[k][:value]
          if v.nil? then
            exit 0            # User ordered "quit"   (Ignore other choices.)
          elsif v == false then
            finished = true   # User requested "back" (Ignore other choices.)
            break
          elsif v.is_a?(Method) then
            collection = []
            choices.keys.each do |k|
              if choices[k][:value].respond_to?(:matches_for) then
                collection << choices[k][:value]
              end
            end
            v.call(collection)
            break
          end
          v
        end
        if values != nil && ! finished then
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
      if response =~ /-/ || response =~ /\.\.?/ then
        lower, upper = response.split(/\s*-\s*|\s*\.\.\s*/, 2)
        if upper == '$' then    # Map '$' to largest index value.
          upper = int_max.to_s
        end
        if lower == '^' then    # Map '^' to smallest index value.
          lower = int_min.to_s
        end
        if is_i?(lower) && is_i?(upper) then
          result = (lower .. upper).to_a
          range_error = lower.to_i < int_min || upper.to_i > int_max
        else
          range_error = true
        end
        if range_error then
          raise "Invalid range specified: #{lower}..#{upper} [#{response}] ("\
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
    result
  end

  def inspect_selected_matches(matches)
    finished = false
    display = BORDER
    matches.each do |match|
      display += "match count for #{match.id}: #{match.count}\n" +
      "time stamp: #{local_time(match.datetime)}\n"
      if match.respond_to?(:owner) && match.owner != nil then
        display += "label: #{match.owner.label}\n"
      end
      display += "MESSAGES:\n"
      match.matches.each do |k, v|
        display += "#{k}:  #{v}\n"
      end
      display += MINOR_BORDER
    end
    while not finished do
      if $stdout.isatty then
        begin
          pager = TTY::Pager.new
          pager.page(display)
        rescue Errno::EPIPE => e
        end
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

  # Components from user selection for execution
  # result is a 2-element array for which:
  #   result[0]:  The method to execute, obtained from 'choice'
  #   result[1]:  Array of arguments for result[0], with 'report' as the
  #               first element
  pre  :args do |report, choice| report != nil && choice != nil end
  post :result do |result| result != nil && result.is_a?(Array) end
  post :foo do |result, rep, c| result.count == 2 && result[1][0] == rep end
  def menu_components(report, choice)
    result = []
    if choice.is_a?(Array) then
      result = [choice[0], [report]]
      if choice.count > 1 then
        result[1].concat(choice[1..choice.count-1])
      end
    else
      result = [choice, [report]]
    end
    result
  end

end
