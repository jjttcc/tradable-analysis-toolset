module TAT
  # Objects representing tradable entities - i.e., stocks, commodities, etc.
  module Tradable
    include Persistent, Contracts::DSL

    public

    #####  Access

    def fields
      # (tracked: Is the tradable flagged as tracked?)
      [:symbol, :name, :tracked]
    end

    def associations
      [:exchange]
    end

    #####  Boolean queries

    # Is this tradable being tracked - i.e., used - by someone?
    # (Alias for 'tracked' - i.e., with '?' added)
    post :invariant do invariant end
    def tracked?
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    #####  State-changing operations

    # Set as 'tracked'.
    post :tracked do tracked? end
    def track!
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    # Set as not 'tracked'.
    post :not_tracked do ! tracked? end
    def untrack!
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

  end
end
