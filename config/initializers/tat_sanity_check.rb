$log = Logger.new("/tmp/mas-client.log#{$$}", 1, 1024000)
$app_startup_in_progress = true
$log.debug("We are here! - asip #{$APP_STARTUP_IN_PROGRESS}")
begin
  mas_client = MasClientTools::mas_client()
rescue => e
  raise "Connection to MAS server failed [#{e}]"
end
$log.debug("TAT sanity check - mas_client: #{mas_client}")
mas_client.request_symbols
symbols = mas_client.symbols
if symbols.empty? then
  raise "symbol list from MAS server is empty. " +
      "[mas_client: #{mas_client.inspect}]"
end
mas_client.logout
