# Tradable (stocks, commodities, etc.) data retrieval services interface
class TradableDataRetriever
  include Contracts::DSL

  public  ###  Access

  # hash-table of data sets (keyed by 'symbol') from the last retrieval
  attr_reader :data_sets

  # The last set of symbols for which data was retrieved via
  # 'retrieve_ohlc_data'
  attr_reader :last_symbols

  # split factors, if any, for the specified symbol (member of last_symbols)
  attr_reader :split_factors_for

  # The metadata, for the specified symbol, resulting from a call to
  # 'retrieve_metadata_for'
  attr_reader :metadata_for

  # The name, for the specified symbol, resulting from a call to
  # 'retrieve_metadata_for'
  def name_for(symbol)
    metadata_for[symbol][@name_key]
  end

  # The exchange, for the specified symbol, resulting from a call to
  # 'retrieve_metadata_for'
  def exchange_for(symbol)
    metadata_for[symbol][@exchange_key]
  end

  # The description, for the specified symbol, resulting from a call to
  # 'retrieve_metadata_for'
  def description_for(symbol)
    metadata_for[symbol][@desc_key]
  end

  public  ###  Basic operations

  # open,high,low,close historical data for the tradables identified
  # Retrieve historical data for the tradables identified by 'symbols', with
  # the specified start_date and end_date - If end_date is nil, an end-date
  # of "now" is used.  The expected date format is: yyyy-mm-dd.
  # On success, 'data_sets' will be a Hash[Array[Array]], keyed by symbol.
  pre :syms_good do |symbols, sd| symbols != nil && symbols.class == Array end
  pre :start_good do |s, start_date|
    start_date != nil && start_date.class == String end
  post :data_sets_result do |result, symbols|
    data_sets.class == Hash && data_sets.count == symbols.count end
  def retrieve_ohlc_data(symbols, start_date, end_date = nil)
    @data_sets = {}
    @last_symbols = symbols
    ohlc_pre_process(symbols)
    if @skip_lines.nil? then
      @skip_lines = 0
    end
    symbols.each do |s|
      query = query_from_symbol(s, start_date, end_date)
      uri = URI(query)
      response = Net::HTTP.get(uri)
      lines = response.split(@record_separator)
      current_data_set = []
      line_number = 1
      lines.each do |l|
        @line = l
        if line_number > @skip_lines then
          current_record = csv_split
          current_data_set << current_record
          if @post_process_lines then
            post_process_current_line(s, current_record)
          end
        end
        line_number += 1
      end
      @data_sets[s] = current_data_set
    end
  end

  # Metadata (e.g.: name, exchange, ...) for the tradable with 'symbol'
  def retrieve_metadata_for(symbol)
    query = metadata_query(symbol)
    uri = URI(query)
    response = Net::HTTP.get(uri)
    @metadata_for[symbol] = parsed_metadata(response)
  end

  private

  def initialize(*args)
    @field_order = [DATE, OPEN, HIGH, LOW, CLOSE, VOLUME, OI]
    @record_separator = "\n"
    @field_separator = ','
    @post_process_lines = false
    @split_factors_for = {}
    @metadata_for = {}
    @exchange_key = 'exchange'
    @name_key = 'name'
    @desc_key = 'description'
  end

  private  ### Implementation - utilities

  DATE, OPEN, HIGH, LOW, CLOSE, VOLUME, OI = 0,1,2,3,4,5,6

  # Result (Array) of reordering (based on @field_order) @line.split(/,/) -
  pre :line do @line != nil end
  post :result do |result| result != nil && result.class == Array end
  def csv_split
    result = []
    limit = @field_order.count + 1
    fields = @line.split(@field_separator, limit)
    (0..@field_order.count-1).each do |i|
      result << fields[@field_order[i]]
    end
    result
  end

  def ohlc_pre_process(symbols)
    symbols.each do |s|
      @split_factors_for[s] = []
    end
  end

end
