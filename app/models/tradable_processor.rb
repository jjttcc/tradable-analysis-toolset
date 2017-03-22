class TradableProcessor < ApplicationRecord

  def self.tradable_processor_by_name(name)
    result = nil
    if ! defined? @@tradable_processor_by_name then
      @@tradable_processor_by_name = {}
    end
    result = @@tradable_processor_by_name[name]
    if result == nil then
      result = TradableProcessor.find_by_name(name)
      if ! result.nil? then
        @@tradable_processor_by_name[name] = result
      end
    end
    result
  end

end
