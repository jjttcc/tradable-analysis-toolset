# Constants relevant to trading-period types
module PeriodTypeConstants

  @@name_for = nil

  public

  ### utility methods ###

  def self.name_for
    if @@name_for == nil
      @@name_for = {}
      self.constants(false).each do |c|
        if c =~ /(.*)_ID$/
          @@name_for[const_get($&)] = "#{const_get($1)}"
        end
      end
    end
    @@name_for
  end

  def self.ids
    hash_tbl = self.name_for
    hash_tbl.keys
  end

  ### IDs ###

  ONE_MINUTE_ID = 60

  TWO_MINUTE_ID = 120

  FIVE_MINUTE_ID = 300

  TEN_MINUTE_ID = 600

  FIFTEEN_MINUTE_ID = 900

  TWENTY_MINUTE_ID = 1200

  THIRTY_MINUTE_ID = 1800

  HOURLY_ID = 3600

  DAILY_ID = 86_400

  WEEKLY_ID = 604_800

  MONTHLY_ID = 2_592_000

  QUARTERLY_ID = 7_776_000

  YEARLY_ID = 31_536_000

  ### names ###

  ONE_MINUTE = "one-minute"

  TWO_MINUTE = "two-minute"

  FIVE_MINUTE = "five-minute"

  TEN_MINUTE = "ten-minute"

  FIFTEEN_MINUTE = "fifteen-minute"

  TWENTY_MINUTE = "twenty-minute"

  THIRTY_MINUTE = "thirty-minute"

  HOURLY = "hourly"

  DAILY = "daily"

  WEEKLY = "weekly"

  MONTHLY = "monthly"

  QUARTERLY = "quarterly"

  YEARLY = "yearly"

end
