class TradableAnalyzer < ApplicationRecord
  belongs_to :mas_session

  public ###  Access

  def description
    result = name.sub(/\s*\(.*/, '')
  end

end
