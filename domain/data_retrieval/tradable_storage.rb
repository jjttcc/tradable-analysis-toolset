# Management of persistent tradable source data
class TradableStorage
  include Contracts::DSL

  public

  #####  Basic queries

  # Number of records obtained for 'symbol' in the last call to
  # 'update_data_stores'
  pre :symbol_exists do |symbol| symbol != nil && ! symbol.empty? end
  def last_update_count_for(symbol)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Boolean queries

  # Did the last call to 'update_data_stores' retrieve no data for 'symbol'?
  # (true if the last call to 'update_data_stores' did not include 'symbol')
  pre :symbol_exists do |symbol| symbol != nil && ! symbol.empty? end
  def last_update_empty_for(symbol)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Has data been retrieved for 'symbol' and, if so, is the retrieved data
  # up-to-date with respect to the specified 'date'? - I.e., is the latest
  # retrieved date for 'symbol' the same or later than 'date'?
  pre :symbol_exists do |symbol| symbol != nil && ! symbol.empty? end
  pre :date_valid do |symbol, date| date != nil && date.length == 10 end
  def data_up_to_date_for(symbol, date)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  State-changing operations

  # Update the persistent data store with specified data for the specified
  # 'symbols'.
  # If startdate.nil?, then, for each symbol, use a startdate of the day
  # after the date of the latest stored record for the corresponding tradable.
  # Note: the 'enddate' argument must be supplied and it must be in the
  # time zone of the exchange(s) for 'symbols' (whose exchanges are expected
  # to all have the same time zone) - so, for example, to retrieve data
  # ending on the current date for the Shanghai exchange and it's now 10pm
  # Wednesday in Hawaii, the 'enddate' will need to be for the following
  # day, Thursday.
  # The expected date format is: yyyy-mm-dd.
#!!!!!TO-DO: Document behavior when error/unexpected-problem occurs!!!!
  pre :keyword_hash do |hash| hash != nil end
  pre :syms_exist do |hash| hash[:symbols] != nil end
  def update_data_stores(symbols:, startdate: nil, enddate: nil)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Remove the last 'n' records from the tradable data-sets associated with
  # 'symbols' (utility for testing).
  pre :syms_exist do |symbols| ! symbols.nil? end
  def remove_tail_records(symbols, n)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

end
