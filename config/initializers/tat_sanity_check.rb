$log = Logger.new("/tmp/mas-client.log#{$$}", 1, 1024000)
if ! Rails.env.test? then
  begin
    mas_client = MasClientTools::mas_client()
  rescue => e
    raise "Connection to MAS server failed [#{e} (backtrace:\n" +
      "#{e.backtrace.join("\n")}]"
  end
  mas_client.logout
end
