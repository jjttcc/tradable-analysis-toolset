
class TestEOD
  include TatServicesFacilities

  private

  def initialize(symbols, channel)
    @eod_test_channel = channel
    @sym_key = new_eod_check_key
    puts "Thanks for all the lovely symbols: #{symbols.inspect}"
    puts "My key is: #{@sym_key}"
    run_the_test(symbols)
  end

  def run_the_test(symbols)
    config = ApplicationConfiguration.new($log)
    message_broker = config.application_message_broker
    pubsub_broker = config.pubsub_broker
    message_broker.add_set @sym_key, symbols
puts "publishing #{@eod_test_channel}, #{@sym_key}"
    pubsub_broker.publish @eod_test_channel, @sym_key
    look_for_completion
  end

  # Watch (subscribe) for completion of eod retrieval.
  def look_for_completion
    #!!!!!
  end

end
