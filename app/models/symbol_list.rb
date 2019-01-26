=begin
  name:       character varying
  description:character varying
  symbols:    integer[]
=end

# Lists of symbols - to be used for, e.g., analysis requests
#!!!!TO-DO: Need a cached hash table: symbol_for (key: id, value: symbol)!!!
class SymbolList < ApplicationRecord
  public

  has_many :symbol_list_assignments

  public

  # The (String) symbol with 'symbol' id of 'symbol_id'
  def self.symbol_for(symbol_id)
    if @@id_to_symbol.empty? then
      self.init_symbol_maps
    end
    @@id_to_symbol[symbol_id]
  end

  # The (Integer) symbol id for 'symbol_value'
  def self.symbol_id_for(symbol_value)
    if @@id_to_symbol.empty? then
      self.init_symbol_maps
    end
    @@symbol_to_id[symbol_value.upcase]
  end

  # The (String[]) actual symbols, corresponding to the (Integer[]) 'symbols'
  def symbol_values
    result = []
    symbols.each do |s|
      result << SymbolList::symbol_for(s)
    end
puts "sv: result: #{result.inspect}"
    result
  end

  private

  def self.init_symbol_maps
    TradableSymbol.all.each do |s|
      @@id_to_symbol[s.id] = s.symbol
      @@symbol_to_id[s.symbol] = s.id
    end
  end

  @@symbol_to_id = {}
  @@id_to_symbol = {}

end
