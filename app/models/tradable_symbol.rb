=begin
 symbol      | character varying           | not null
 exchange_id | integer
 tracked     | boolean                     | not null default false
=end

class TradableSymbol < ApplicationRecord
  include Contracts::DSL, TAT::Tradable

  public

  #####  Access

  belongs_to :exchange

  scope :tracked_tradables, -> { where('tracked = ?', true) }

  def name
    record = TradableEntity.find_by_symbol(symbol)
    record.name
  end

  #####  Boolean queries

  # Is this tradable being tracked - i.e., used - by someone?
  # (Alias for 'tracked' - i.e., with '?' added)
  def tracked?
    tr = self
    if tracked.nil? then
      tr = load
    end
    tr.tracked
  end

  #####  State-changing operations

  def track!
    ts = self
    if tracked.nil? then
      ts = load
    end
    if ! ts.tracked then
      self.update_attribute(:tracked, true)
    end
  end

  def untrack!
    ts = self
    if tracked.nil? then
      ts = load
    end
    if ts.tracked then
      self.update_attribute(:tracked, false)
    end
  end

end
