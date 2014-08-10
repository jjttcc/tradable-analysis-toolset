#!/usr/bin/env ruby

require 'ruby_contracts'


# Client-side representation of objects on the server side responsible for
# analyzing tradable data and resulting producing signal output
class TradableAnalyzer
  include Contracts::DSL

  public

  attr_reader :name, :id

  private

  def initialize(name, id)
    @name = name
    @id = id
  end

end
