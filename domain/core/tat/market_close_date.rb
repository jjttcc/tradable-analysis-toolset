module TAT
  module MarketCloseDate
    include Persistent, Contracts::DSL

    public

    def fields
      [:year, :month, :day, :reason]
    end

    def associations
      [:markets]
    end

  end
end
