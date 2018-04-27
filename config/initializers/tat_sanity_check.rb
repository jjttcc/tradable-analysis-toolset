$log = Logger.new("/tmp/mas-client.log#{$$}", 1, 1024000)
begin
  mas_client = MasClientTools::mas_client()
rescue => e
  raise "Connection to MAS server failed [#{e} (backtrace:\n" +
    "#{e.backtrace.join("\n")}]"
end
$log.debug("TAT sanity check - mas_client: #{mas_client}")
mas_client.request_symbols
symbols = mas_client.symbols
if symbols.empty? then
  raise "symbol list from MAS server is empty. " +
      "[mas_client: #{mas_client.inspect}]"
end
mas_client.logout
