# File-based management of tradable source data
class FileTradableStorage < TradableStorage
  include Contracts::DSL

  public  ###  Status report

  # Did the last call to 'update_data_stores' produce an empty result for
  # 'symbol'?  (false if the last call to 'update_data_stores' did not
  # include 'symbol')
  def last_update_empty_for(symbol)
    ! @last_update_rec_count.has_key?(symbol) ||
      @last_update_rec_count[symbol] == 0
  end

  public  ###  Basic operations

  def update_data_stores(symbols, startdate = nil, enddate = nil)
    if startdate.nil? then
      # Use the latest start-date from the existing data for each symbol.
      symbols.each do |s|
        start = startdate_for(s)
        if start.nil? then
          $log.error("Could not find startdate for #{s}")
        else
          retriever.retrieve_ohlc_data([s], start)
          update_data_for(s, retriever.data_sets[s])
        end
      end
    else
      # Use the original startdate and enddate arguments.
      retriever.retrieve_ohlc_data(symbols, startdate, enddate)
      symbols.each do |s|
        update_data_for(s, retriever.data_sets[s])
      end
    end
  end

  def remove_tail_records(symbols, n)
    if n > 0 then
      symbols.each do |s|
        path = path_for s
        if FileTest.exist?(path) then
          newpath = "#{path}.orig#{$$}"
          File.rename(path, newpath)
          origlines = File.readlines(newpath)
          File.open(path, 'w') do |f|
            if origlines.count > 1 then
            origlines[0..origlines.count-2].each do |line|
              f.write(line)
            end
            else
              # origlines.count <= 1, so leave f empty.
            end
          end
          File.unlink(newpath)
        end
      end
    end
  end

  private

  attr_reader :retriever, :data_path

  EXT, FSEP, RSEP, BEGINNING_OF_TIME, DATE_INDEX =
    '.txt', ',', "\n", '1950-01-01', 0

  pre :path_exists do |dp| dp != nil end
  pre :retriever_exists do |dp, retriever| retriever != nil end
  def initialize(data_path, retriever)
    @data_path = data_path
    @retriever = retriever
    @last_update_rec_count = {}
  end

  private  ### Implementation - utilities

  # (nil if an unrecoverable error occurs)
  def startdate_for(symbol)
    result = BEGINNING_OF_TIME
    path = path_for symbol
    if FileTest.exist?(path) then
      file = FileTail.new(path)
      lastline = file.last_n_lines(1)
      if lastline != nil then
        datestr = lastline[0].split(FSEP)[0]
        if datestr.length == 8 then
          datestr = "#{datestr[0..3]}-#{datestr[4..5]}-#{datestr[6..7]}"
          result = (Date.parse(datestr) + 1).to_s
        end
      end
    end
    result
  rescue StandardError => e
    $log.error(e)
    return nil
  end

  def update_data_for(symbol, data_set)
    @last_update_rec_count[symbol] = data_set.count
    path = path_for symbol
    File.open(path, 'a') do |f|
      data_set.each do |fields|
        # (Write date field, stripped of '-' separators.)
        date = fields[0]
        f.write(date[0..3] + date[5..6] + date[8..9] + FSEP)
        f.write(fields[1..fields.count-1].join(FSEP) + "\n")
      end
    end
  rescue StandardError => e
    $log.error("Write to file #{path} failed: #{e}")
  end

  def path_for(symbol)
    File.join(data_path, symbol.downcase + EXT)
  end

end
