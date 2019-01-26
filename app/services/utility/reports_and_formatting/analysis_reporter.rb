class AnalysisReporter
  public

  attr_accessor :source

  def summary
    result = "This is a mostly useless summary.\n(source: #{source.inspect})"
    if source.has_events? then
      allev = source.all_events
      result += "\n#{allev.count} events:\n\n"
      allev.each do |e|
        result += "#{e}\n"
      end
    else
      result += "\nNO EVENTS!  That is Bad!"
    end
    result
  end

  def summary_html
    '<html>' +
    '<body>' +
    '<p>' +
    "This is a useless summary.</p><p>(source: #{source.inspect})" +
    '</p>' +
    '</body>' +
    '</html>'
  end

end
