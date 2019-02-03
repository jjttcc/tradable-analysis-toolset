=begin
 name              | character varying           | not null
 type              | integer                     | not null default 1
 timezone          | character varying           | not null
=end


class Exchange < ApplicationRecord
  include Contracts::DSL

  public

  has_many   :close_date_links, as: :market
  has_many   :market_close_dates, through: :close_date_links
  has_many   :market_schedules, as: :market

  public

  # Is this exchange open for trading?
  def is_open?
    #!!!!!!!TBI!!!!!!
  end

  # Is the current time within the core trading hours for this exchange?
  post :is_open_if_true do |result| implies(result, is_open?) end
  def is_open_core?
    #!!!!!!!TBI!!!!!!
  end

  private

  self.inheritance_column = :sti_not_used

  enum type: {
    stock:          1,
    commodity:      2,
    currency:       3,
    #...
  }

end
