require 'ruby_contracts'

module ReportTools
  include Contracts::DSL, TatUtil

  public

  COUNT_LIMIT = 5

  # Summary of the counts of components of 'r'
  pre  :rep_good do |h| h[:report] != nil && h[:report].is_a?(Enumerable) end
  pre  :lbl_good do |h| h[:label].nil? || h[:label].is_a?(String)         end
  pre  :cl_good  do |h|
    h[:count_limit].nil? || h[:count_limit].is_a?(Integer) end
  post :result do |result| result != nil end
  def count_summary(report:, count_limit: COUNT_LIMIT, label: "")
    result = label
    same_counts = {}
    if ! result.empty? then
      result += ":\n"
    end
    count_lines = {}
    report.each do |e|
      if ! count_lines.has_key?(e.count) then
        count_lines[e.count] = [e.handle]
      else
        count_lines[e.count] << e.handle
      end
    end
    count_lines.keys.sort.each do |k|
      if count_lines[k].count > count_limit then
        same_counts[k] = count_lines[k].count
      else
        result += "#{count_lines[k].join(", ")}: #{k}\n"
      end
    end
    same_counts.keys.each do |count|
      result += "#{same_counts[count]} elements with count: #{count}\n"
    end
    result
  end

  pre :target_enum_or_has_matches_for do |tgt|
    tgt != nil && (tgt.is_a?(Enumerable) || tgt.respond_to?(:matches_for)) end
  def collected_matches(target, regexp, use_keys, use_values)
    result = []
    if target.respond_to?(:matches_for) then
      result = target.matches_for(regexp, use_keys: use_keys,
                                  use_values: use_values)
    else
      target.each do |o|
        matches = o.matches_for(regexp, use_keys: use_keys,
                                use_values: use_values)
        if matches != nil && matches.count > 0 then
          if matches.is_a?(Array) then
            result.concat(matches)
          else
            result << matches
          end
        end
      end
    end
    result
  end

  # Return a line-wrapped version of the specified string, 's'.
  # (Borrowed/adapted from NateSHolland [
  # https://stackoverflow.com/users/1415546/natesholland ] at
  # https://stackoverflow.com/questions/49244740/wrap-the-long-lines-in-ruby )
  pre  :s_exists do |s| s != nil && s.is_a?(String) end
  pre  :sane_indent do |s, mxlen, ind| ind.nil? || ind.length < mxlen end
  post :exists do |result, s| result != nil && result.length >= s.length end
  def wrap(s, max_length = 72, indent = nil)
    result = ""
    line1_length, line_n_length = max_length, max_length
    if indent != nil && indent.length > 0 then
      line_n_length = max_length - indent.length
    end
    word_array = s.split(/\s|-/)
    line = word_array.shift
    max_len = line1_length
    adjust_lengths = lambda do
      if ! line1_length.nil? then
        max_len = line_n_length
        line1_length = nil
      end
    end
    word_array.each do |word|
      if (line + " " + word).length <= max_len then
        line << " " + word
      elsif word.length > max_len then
        result << line + "\n#{indent}" unless line.empty?
        adjust_lengths.call
        line = ""
        word.each_char do |c|
          line << c
          if line.length == max_len then
            result << line + "\n#{indent}"
            adjust_lengths.call
            line = ""
          end
        end
      else
        result << line + "\n#{indent}"
        adjust_lengths.call
        line = word
      end
    end
    result << line
    result
  end

  # DateTime obtained from user - if 'refresh', take the "refresh" the
  # internal state (such as timezone offset).
  def prompted_datetime(dt_label, refresh = true)
    result = nil
    finished = false
    if dt_label.nil? then
      dt_label = ""
    elsif ! dt_label.empty? then
      dt_label = "<#{dt_label}> "
    end
    if @now.nil? || refresh then
      @now = DateTime.now
    end
    timezone_offset = (@now.utc_offset / 3600).to_s
    dt_template = [@now.year, @now.month, @now.day, @now.hour, @now.minute, 0]
    prompt = TTY::Prompt.new
    while ! finished do
      response = prompt.ask("Enter #{dt_label}date/time (empty for \"now\")")
      if response.nil? then
        result = @now
      else
        dt_parts = []
        i = 0
        response_parts = response.split(/[-\/ :]+/)
        (0..5).each do |i|
          part = response_parts[i]
          if ! is_i?(part) then
            case part
            when /[._a-wyz]/
              dt_parts[i] = dt_template[i]
            when /x/
              n = 0
              if i == 1 || i == 2 then                # month or day
                n = 1
              end
              dt_parts[i] = n
            when nil
              dt_parts[i] = dt_template[i]
            end
          else
            dt_part = part.to_i
            if dt_part == 0 && (i == 1 || i == 2) then    # month or day
              dt_part = 1    # Correct to valid month-or-day.
            end
            dt_parts[i] = dt_part
          end
        end
        y, m, d, h, min, s = dt_parts
        result = DateTime.new(y, m, d, h, min, s, timezone_offset)
      end
      puts "#{dt_label}date/time: #{result}"
      response = prompt.ask('OK?')
      if response =~ /y/i then
        finished = true
      end
    end
    result
  end

end
