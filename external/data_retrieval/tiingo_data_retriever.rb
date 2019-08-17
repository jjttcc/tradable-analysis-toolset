require 'net/http'
require 'json'
require 'tradable_data_retriever'

=begin
example query:
https://api.tiingo.com/tiingo/daily/IBM/prices?token=<token>&startDate=2019-1-30&endDate=2019-1-31&format=csv
example response:
date,close,high,low,open,volume,adjClose,adjHigh,adjLow,adjOpen,adjVolume,divCash,splitFactor
2019-01-30,134.38,135.03,133.25,134.0,4500919,134.38,135.03,133.25,134.0,4500919,0.0,1.0
2019-01-31,134.42,134.716,133.74,134.45,4884031,134.42,134.716,133.74,134.45,4884031,0.0,1.0

metadata query format:
https://api.tiingo.com/tiingo/daily/<ticker>
returns: ticker, name, description, exchange, start-date, end-date
=end

# Retrieval of tradable data from tiingo.com
# API documentation:
# https://api.tiingo.com/docs/tiingo/overview
class TiingoDataRetriever < TradableDataRetriever

  private

  FORMAT = '&format=csv'
  TOKEN_ENV_VAR = 'TIINGO_TOKEN'
  BASE_URL = 'https://api.tiingo.com/tiingo/daily'
  NEUTRAL_SPLIT_FACTOR = '1.0'

  def initialize(token, log)
    super(token)
    @token = token
    # (Override @field_order, @post_process_lines:)
    @field_order = [DATE, CLOSE, HIGH, LOW, OPEN, VOLUME]
    @post_process_lines = true
    @skip_lines = 1
    @exchange_key = 'exchangeCode'
    @log = log
  end

  private  ### Hook method implementations

  def query_from_symbol(s, start_date, end_date)
    result = "#{BASE_URL}/#{s}/prices?token=#{@token}" + '&startDate=' +
      start_date
    if ! end_date.nil? then
      result += '&endDate=' + end_date
    end
    result += FORMAT
  end

  def metadata_query(symbol)
    result = "https://api.tiingo.com/tiingo/daily/#{symbol}?token=#{@token}"
  end

  def parsed_metadata(response)
    JSON.parse(response)
  end

  # Post-process current @line for current 'symbol' (with 'current_record',
  # if needed).
  # (Look for and store non-neutral split factor.)
  def post_process_current_line(symbol, current_record)
    split_factor = @line.rpartition(@field_separator)[-1]
    if split_factor != NEUTRAL_SPLIT_FACTOR then
      date = current_record[0]
      @split_factors_for[symbol] << [date, split_factor]
      @log.debug("split_factor (#{symbol}): #{[date, split_factor].inspect}")
    end
  end

end
