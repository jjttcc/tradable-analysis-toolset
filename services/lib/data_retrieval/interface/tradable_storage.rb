# Management of persistent tradable source data
class TradableStorage
  include Contracts::DSL

  public  ###  Status report

  # Did the last call to 'update_data_stores' retrieve no data for 'symbol'?
  # (true if the last call to 'update_data_stores' did not include 'symbol')
  def last_update_empty_for(symbol)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Number of records obtained for 'symbol' in the last call to
  # 'update_data_stores'
  def last_update_count_for(symbol)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  public  ###  Basic operations

  # Update persistent data store with latest data for the specified 'symbols'.
  # If startdate.nil?, base the start-date, for each symbol, on the latest
  # available record for the corresponding tradable.
  # If startdate.nil? or enddate.nil?, use an end-date of "now".
  # The expected date format is: yyyy-mm-dd.
#!!!!!TO-DO: Document behavior when error/unexpected-problem occurs!!!!
  pre :syms_exist do |symbols| symbols != nil end
  def update_data_stores(symbols, startdate = nil, enddate = nil)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Remove the last 'n' records from the tradable data-sets associated with
  # 'symbols' (utility for testing).
  pre :syms_exist do |symbols| ! symbols.nil? end
  def remove_tail_records(symbols, n)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

end
