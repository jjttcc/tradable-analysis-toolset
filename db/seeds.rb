# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

############################ TEST DATA ONLY ###################################

if ENV['RAILS_ENV'] == "test"
#!!!!!?:   require 'period_type_constants'
#!!!!!?:   connection = ActiveRecord::Base.connection()
  require_relative '../test/test_constants'

  admin_email, nonadmin_email = TestConstants::ADMIN_EMAIL,
    TestConstants::NONADMIN_EMAIL
  admin_pw, nonadmin_pw = TestConstants::ADMIN_PW, TestConstants::NONADMIN_PW
  if User.find_by_email_addr(admin_email) == nil
    #### Ensure both an 'admin' and a non-admin user resides in the DB.
    user = User.create!(:email_addr => admin_email,
                        :password => admin_pw,
                        :password_confirmation => admin_pw)
    user.toggle!(:admin)
    user = User.create!(:email_addr => nonadmin_email,
                        :password => nonadmin_pw,
                        :password_confirmation => nonadmin_pw)
    a = User.find_by_email_addr(admin_email)
    u = User.find_by_email_addr(nonadmin_email)
    if a.nil? or u.nil?
      throw "failed to save admin or non-admin"
    end
  end
end

############################ REFERENCE DATA ###################################
require 'csv'
SYM = 'symbol'; NAME = 'name'; TYPE = 'type'; TZ = 'timezone'
DATE = 'date'

def load_tradable_entities_and_symbols
  if ! TradableEntity.find_by_symbol('IBM').nil? then
    return
  end
  puts "loading tradable_entities table"
  entities = {}
  symbols = []
  converter = lambda { |header| header.downcase }
  csv_text = File.read(Rails.root.join('db','allusstocks.csv'))
  csv = CSV.parse(csv_text, :headers => true, header_converters: converter)
  i=1
  csv.each do |row|
    row.to_hash
    if entities.has_key?(row[SYM]) then
      $stderr.puts "duplicate key found on line #{i}"
    else
      symbol = row[SYM].strip
      entities[row[SYM]] = TradableEntity.new(
        symbol: symbol, name: row[NAME].strip)
      symbols << TradableSymbol.new(symbol: symbol)
    end
    i += 1
  end
  TradableEntity.transaction do
    entities.each do |key, value|
      value.save!
    end
    symbols.each { |s| s.save! }
  end
end

def initialize_symbol_lists
  if ! SymbolList.find_by_name('all').nil? then
    return
  end
  SymbolList.create!(name: 'all', description: nil, symbols: nil)
end

def loaded_exchanges
  if ! Exchange.find_by_name('NASDAQ').nil? then
    exchanges = Exchange.all.map { |e| [e.name, e] }.to_h
  else
    exchanges = {}
    Exchange.transaction do
      converter = lambda { |header| header.downcase }
      csv_text = File.read(Rails.root.join('db','exchanges.csv'))
      csv = CSV.parse(csv_text, :headers => true, header_converters: converter)
      i=1
      csv.each do |row|
        row.to_hash
        name = row[NAME].strip.upcase
        if exchanges.has_key?(name) then
          $stderr.puts "duplicate key found on line #{i}"
        else
          exch = Exchange.new(name: name, type: row[TYPE].to_i,
                              timezone: row[TZ].strip)
          exchanges[name] = exch
          exch.save
        end
        i += 1
      end
    end
  end
  exchanges
end

STYPE, PRE_START, PRE_END, CORE_START, CORE_END, POST_START, POST_END, MKTLBL =
  'schedule_type', 'pre_market_start_time', 'pre_market_end_time',
  'core_start_time', 'core_end_time', 'post_market_start_time',
  'post_market_end_time', 'market-label'

def load_market_schedules(exchanges)
  # Note: a candidate key consists of 'schedule_type', 'date', 'market_id'.
  if MarketSchedule.count == 0 then
    fnames = [STYPE, DATE, PRE_START, PRE_END, CORE_START, CORE_END,
              POST_START, POST_END]
    MarketSchedule.transaction do
      converter = lambda { |header| header.downcase }
      csv_text = File.read(Rails.root.join('db','market_schedule.csv'))
      csv = CSV.parse(csv_text, :headers => true, header_converters: converter)
      mktlbl_index = fnames.count
      csv.each do |row|
        if row.count > 1 then
          timezone = nil
          ms = MarketSchedule.new
          market = row[mktlbl_index].strip.upcase
          exch = exchanges[market]
          if exch != nil then
            ms.market = exch
            timezone = exch.timezone
          end
          (0..fnames.count-1).each do |i|
            case fnames[i]
            when STYPE then
              value = row[i].to_i
            when DATE then
              value = (row[i].blank?)? nil: row[i].strip
            else
              value = (row[i].blank?)? nil: row[i].strip
            end
#!!!puts "field #{i}: #{fnames[i]}, value: #{value}"
            ms.write_attribute(fnames[i].to_sym, value)
          end
          ms.save!
        else
          # row.count <= 1 -> found extra/invalid stuff: ignore it.
        end
      end
    end
  end
end

def old___load_market_schedules(exchanges)
  # Note: a candidate key consists of 'schedule_type', 'date', 'market_id'.
  if MarketSchedule.count == 0 then
    fnames = [STYPE, DATE, PRE_START, PRE_END, CORE_START, CORE_END,
              POST_START, POST_END]
    MarketSchedule.transaction do
      converter = lambda { |header| header.downcase }
      csv_text = File.read(Rails.root.join('db','market_schedule.csv'))
      csv = CSV.parse(csv_text, :headers => true, header_converters: converter)
      finished = false
      csv.each do |row|
        ms = MarketSchedule.new
        (0..fnames.count-1).each do |i|
          case fnames[i]
          when STYPE then
            value = row[i].to_i
          when DATE then
            value = (row[i].blank?)? nil: Date.parse(row[i].strip)
          else
            value = (row[i].blank?)? nil: Time.parse(row[i].strip)
          end
puts "field #{i}: #{fnames[i]}, value: #{value}"
          if value == 0 then
            puts "Found 0 schedule_type value - ending load."
            finished = true
            break
          end
          ms.write_attribute(fnames[i].to_sym, value)
        end
        if not finished then
          row.to_hash
          market = row[MKTLBL].strip.upcase
          exch = exchanges[market]
          if exch != nil then
            ms.market = exch
          end
          ms.save!
        else
          break
        end
      end
    end
  end
end

CLOSE_YEAR, CLOSE_MONTH, CLOSE_DAY, CLOSE_REASON = 0,1,2,3

def loaded_market_closes
  closes = {}
  if MarketCloseDate.count == 0 then
    MarketCloseDate.transaction do
      converter = lambda { |header| header.downcase }
      csv_text = File.read(Rails.root.join('db','market_closes.csv'))
      csv = CSV.parse(csv_text, :headers => true, header_converters: converter)
      csv.each do |row|
        reason = row[CLOSE_REASON].strip
        if ! closes.has_key?(reason) then
          closes[reason] = []
        end
        year = row[CLOSE_YEAR].to_i
        month = row[CLOSE_MONTH].to_i
        day = row[CLOSE_DAY].to_i
        close = MarketCloseDate.new(reason: reason, year: year, month: month,
                                    day: day)
        closes[reason] << close
        close.save!
      end
    end
  else
    all_closes = MarketCloseDate.all
    all_closes.each do |close|
      if ! closes.has_key?(close.reason) then
        closes[close.reason] = []
      end
      closes[close.reason] << close
    end
  end
  closes
end

CLINK_REASON, CLINK_MARKET = 0,1

def link_to_exch(closes, exchanges)
  if CloseDateLink.count == 0 then
    CloseDateLink.transaction do
      converter = lambda { |header| header.downcase }
      csv_text = File.read(Rails.root.join('db','closedate_links.csv'))
      csv = CSV.parse(csv_text, :headers => true, header_converters: converter)
      csv.each do |row|
        reason = row[CLINK_REASON].strip
        market = row[CLINK_MARKET]
        if ! closes.has_key?(reason) then
          puts "#{__method__} - error: no '#{reason}' in 'closes'"
        else
          closes[reason].each do |close|
            link = CloseDateLink.new
            exchange = exchanges[market]
            link.market = exchange
            link.market_close_date = close
            link.save!
          end
        end
      end
    end
  end
end

def load_market_exchange_info
  exchanges = loaded_exchanges
  load_market_schedules(exchanges)
  closes = loaded_market_closes
  link_to_exch(closes, exchanges)
end

load_tradable_entities_and_symbols
initialize_symbol_lists
load_market_exchange_info
Exchange.all.each do |e|
  e.market_close_dates.each do |l|
  end
  e.market_schedules.each do |s|
  end
end
