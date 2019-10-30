module ReportTools
  public

  COUNT_LIMIT = 5

  # Summary of the counts of components of 'r'
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

end
