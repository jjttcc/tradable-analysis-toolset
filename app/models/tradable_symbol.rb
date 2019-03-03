=begin
 symbol      | character varying           | not null
 exchange_id | integer
 tracked     | boolean                     | not null default false
=end

class TradableSymbol < ApplicationRecord
  include Contracts::DSL

  public

  belongs_to :exchange

  scope :tracked_tradables, -> { where('tracked = ?', true) }

  public ###  Status report

  # Is this tradable being tracked - i.e., used - by someone?
  # (Alias for 'tracked' - i.e., with '?' added)
  def tracked?
    tr = self
    if tracked.nil? then
      tr = load
    end
    tr.tracked
  end

  public  ###  Basic operations

  # Set as 'tracked'.
  post :tracked do tracked? end
  def track!
    ts = self
    if tracked.nil? then
      ts = load
    end
    if ! ts.tracked then
      self.update_attribute(:tracked, true)
    end
  end

  # Set as not 'tracked'.
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
