=begin
 symbol         | character varying           | not null
 created_at     | timestamp without time zone | not null
 updated_at     | timestamp without time zone | not null
 exchange_id    | integer
 # number of entities/clients tracking the associated tradable:
 tracking_count | integer                     | not null default 0
=end

class TradableSymbol < ApplicationRecord
  include Contracts::DSL

  public

  belongs_to :exchange

  scope :tracked, -> { where('tracking_count > 0') }

  public ###  Status report

  # Is this tradable being tracked - i.e., used - by someone?
  def tracked?
    ts = self
    if tracking_count.nil? then
      ts = load
    end
    ts.tracking_count > 0
  end

  public  ###  Basic operations

  # Increment the 'tracking_count' and save the record (self).
  post :tracked do tracked? end
  def track!
    ts = self
    if tracking_count.nil? then
      ts = load
    end
    self.update_attribute(:tracking_count, ts.tracking_count + 1)
  end

  # If 'tracking_count' > 0, decrement it and save the record (self).
  def untrack!
    ts = self
    if tracking_count.nil? then
      ts = load
    end
    if ts.tracking_count > 0 then
      self.update_attribute(:tracking_count, ts.tracking_count - 1)
    end
  end

end
