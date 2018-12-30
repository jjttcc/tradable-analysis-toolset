class EmailNotifier < Notifier
  include Contracts::DSL

  private

  def perform_execution(notification_source)
    report_extractor.source = notification_source
    report = report_extractor.summary
    set_email_fields(report)
    send_email(report, notification_source)
#!!!begin stub:!!!
    @execution_succeeded = true
    notifications.each do |n| n.sent! end
#!!!end stub!!!
  end

  pre :required_fields_set do
    [@to, @from, @subject, @body].each {|f| ! f.nil? && ! f.empty?} end
  def send_email(report, notification_source)
    raise "abstract method: EmailNotifier.send_email"
  end

  post :required_fields_set do
    [@to, @from, @subject, @body].each {|f| ! f.nil? && ! f.empty?} end
  def set_email_fields(report)
    @to = notifications.map do |n|
      n.contact_identifier
    end.join(",")
    @subject = 'TAT mail test'
    @body    = report
    @custom_header = 'TATDEV'
    @from = from_address
#    @mail.content_type = 'text/plain' #!!!!
#    @mail.charset = 'us-ascii' #!!!!
  end

  post :from_set do |result| ! result.nil? && ! result.empty? end
  def from_address
    raise "abstract method: EmailNotifier.from_address"
  end

end
