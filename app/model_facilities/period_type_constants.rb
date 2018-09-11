# Constants relevant to trading-period types
module PeriodTypeConstants
  include Contracts::DSL
  include TimePeriodTypeConstants

  @@name_for = nil

  public

  ### utility methods ###

  # hash table: key: id, value: name
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

  # The 'id' for 'name', if 'name' is a valid period-type name
  pre :valid_pt_name do |name| valid_period_type_name(name) end
  post :valid_id do |result, name| name_for[result] == name end
  def self.id_for(name)
    # (Force creation of @@name_for hash.)
    if @@name_for.nil? then name_for[ONE_MINUTE_ID] end
    result = @@name_for.keys.find { |id| @@name_for[id] == name }
  end

  def self.ids
    hash_tbl = self.name_for
    hash_tbl.keys
  end

  def self.valid_period_type_name(name)
    @@period_types.include?(name)
  end

  ### IDs, based on seconds-per-period-type ###
  # (period-type name constants are defined in TimePeriodTypeConstants.)

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

end
