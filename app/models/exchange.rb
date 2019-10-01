=begin
 name              | character varying           | not null
 type              | integer                     | not null default 1
 timezone          | character varying           | not null
 full_name         | character varying
=end

class Exchange < ApplicationRecord
  include Contracts::DSL, TAT::Exchange

  public

  #####  Access

  has_many   :close_date_links, as: :market
  has_many   :market_close_dates, through: :close_date_links
  has_many   :market_schedules, as: :market

  post :result_exists do |result| result != nil end
  def updated_components(datetime)
    result = []
    if updated_at > datetime then
      result << self
    end
    market_schedules.each do |s|
      if s.updated_at > datetime then
        result << s
      end
    end
    market_close_dates.each do |mcd|
      if mcd.updated_at > datetime then
        result << mcd
      end
    end
    result
  end

  #####  State-changing operations

  def reload
    super
    self.current_local_time = nil
    cached_current_schedule = nil
  end

  protected ##### Hook method implementations

  def closed_dates(year, month, day)
    MarketCloseDate::close_date_for_exchange_id(year, month, day, id)
  end

  private

  self.inheritance_column = :sti_not_used

  enum type: {
    stock:          1,
    ecn:            2,
    commodity:      3,
    currency:       4,
    #...
  }

  private ##### Initialization

  # Ensure that precondition of TimeUtilities.current_date_time is
  # fulfilled (:time_utilities_imp_exists)
  after_initialize do |current|
    current.time_utilities_implementation = TimeUtil
  end

end
