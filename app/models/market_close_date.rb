=begin
 year       | integer                     | not null
 month      | integer                     | not null
 day        | integer                     | not null
 reason     | character varying           | not null
=end

class MarketCloseDate < ApplicationRecord
  include Contracts::DSL

  public

  has_many   :close_date_links
  has_many   :markets, through: :close_date_links

  # The MarketCloseDate(s) (almost always 1 record) for the specified year,
  # month, day
  scope :close_date_for, ->(year, month, day) {
    where("year = ? and month = ? and day = ?", year, month, day)
  }

  # The MarketCloseDate(s) (almost always 1 record) for the specified year,
  # month, day, and close_date_links.market_id
  scope :close_date_for_exchange_id, ->(year, month, day, exchange_id) {
      joins(:close_date_links).where(
        "year = ? and month = ? and day = ? and close_date_links.market_id = ?",
        year, month, day, exchange_id)
  }

end
