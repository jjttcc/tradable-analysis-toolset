# Abstraction for time-based monitoring of exchanges (such as: When is the
# earliest upcoming market-closing time and which exchanges will close at
# that time?)
module TAT
  module ExchangeClock
    include Contracts::DSL, TatUtil

    public  ###  Access

    # All exchanges in the database
    attr_reader :exchanges

    # The date/time at which 'exchanges' was last initialized
    attr_reader :initialization_time

    # The exchanges associated with 'close_time' (datetime returned by
    # 'next_close_time')
    pre  :time_exists do |close_time| close_time != nil end
    post :enumerable do |result|
      implies(result != nil, result.is_a?(Enumerable)) end
    post :holds_exchanges do |res| implies(res != nil && res.count > 0,
                                     res.first.is_a?(TAT::Exchange)) end
    def exchanges_for(close_time)
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

  end
end
