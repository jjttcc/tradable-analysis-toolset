class MarketSchedule < ApplicationRecord
  public

  belongs_to :market, polymorphic: true

  public

  enum schedule_type: {
    mon_fri:        1, # Monday through Friday
    seven_day:      2, # all 7 days a week
    sun_thu:        3, # Sunday through Thursday
    sat_wed:        4, # Saturday through Wednesday
    holiday:        5, # on or near holiday (probably with shortened hours)
  }

end
