class CloseDateLink < ApplicationRecord
  belongs_to :market, polymorphic: true
  belongs_to :market_close_date
end
