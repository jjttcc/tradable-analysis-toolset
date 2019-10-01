=begin
 schedule_type          | integer                     | not null default 1
 date                   | character varying
 pre_market_start_time  | character varying
 pre_market_end_time    | character varying
 post_market_start_time | character varying
 post_market_end_time   | character varying
 core_start_time        | character varying           | not null
 core_end_time          | character varying           | not null
=end

class MarketSchedule < ApplicationRecord
  include Contracts::DSL, TAT::MarketSchedule

  public

  belongs_to :market, polymorphic: true

  enum schedule_type: {
    mon_fri:        MON_FRI,    # Monday through Friday
    seven_day:      SEVEN_DAY,  # all 7 days a week
    sun_thu:        SUN_THU,    # Sunday through Thursday
    sat_wed:        SAT_WED,    # Saturday through Wednesday
    holiday:        HOLIDAY ,   # on or near holiday (possibly: shortened hours)
  }

  public  ###  Access

  def schedule_type_as_integer
    MarketSchedule.schedule_types[schedule_type]
  end

  private ##### Initialization

  # Ensure that the invariant of TimeUtilities is fulfilled.
  after_initialize do |current|
    current.time_utilities_implementation = TimeUtil
  end

end
