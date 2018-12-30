class SMTP_Notifier < EmailNotifier
  require 'mail'

  public

  def send_email(report, notification_source)
    @mail = Mail.new
    @mail.to      = @to
    @mail.from    = @from
    @mail.subject = @subject
    @mail.body    = @body
    if ! @custom_header.nil? && ! @custom_header.empty? then
      @mail.header['X-Custom-Header'] = @custom_header
    end
    @mail.deliver
  end

  def from_address
    ENV["SMTP_FROM_ADDRESS"]
  end

  private

  @@options = { :address              => ENV["SMTP_SERVER"],
                :port                 => ENV["SMTP_PORT"],
                :user_name            => ENV["SMTP_LOGIN"],
                :password             => ENV["SMTP_PASSWORD"],
                :authentication       => 'plain',
                :enable_starttls_auto => true  }

  Mail.defaults do
    delivery_method :smtp, @@options
  end

end
