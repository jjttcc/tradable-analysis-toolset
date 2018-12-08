=begin
name:        text
event_id:    integer
is_intraday: boolean
=end

class TradableAnalyzer < ApplicationRecord
  public ###  Access

#!!!!TEMPORARY stub:
def period_type; 'monthly' end

  def description
    result = name.sub(/\s*\(.*/, '')
  end

end
