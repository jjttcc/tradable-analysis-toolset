require 'json'
require 'ruby_contracts'

# Value (immutable) objects that mimic a read-only Hash to provide the
# specifications for a status report
class ReportSpecification
  include Contracts::DSL

  public

  #####  Constants

  # Values of keys used for reporting
  REPORT_KEY_KEY, KEYS_KEY, BLOCK_KEY, NEW_KEY =
    :response_key, :key_list, :block_msecs, :new_only

  BLOCK_MSECS_DEFAULT = 2000

  QUERY_KEYS = [REPORT_KEY_KEY, KEYS_KEY, BLOCK_KEY, NEW_KEY]

  QUERY_KEY_MAP = Hash[QUERY_KEYS.map {|e| [e, true]}]

  #####  Access

  # The key with which the StatusReporting object is expected to log its
  # response - the report results
  attr_reader :response_key

  # The list of keys for which log entries are to be retrieved
  attr_reader :key_list

  attr_reader :block_msecs, :new_only

  # The hash-table/arguments needed to retrieve the ordered report
  def retrieval_args
    result = to_hash.select do |k, v|
      k != :response_key
    end
  end

  pre :is_key do |k| k.is_a?(Symbol) || k.is_a?(String) end
  def [](key)
    result = nil
    if QUERY_KEY_MAP[key.to_sym] then
      result = self.send(key)
    end
    result
  end

  def keys
    self.to_hash.keys
  end

  #####  Boolean queries

  pre :is_key do |k| k.is_a?(Symbol) || k.is_a?(String) end
  def has_key?(key)
    QUERY_KEY_MAP[key.to_sym]
  end

  #####  Conversion

  # (To provide arguments to LogReader.contents_for)
  def to_hash
    h = Hash[ QUERY_KEY_MAP.keys.map do |e|
      [e, self[e]]
    end]
  end

  def to_str
    self.to_hash.to_json
  end

  def to_json
    self.to_hash.to_json
  end

  private

  pre  :contents do |contents| contents != nil end
  post :new_only_boolean do |result|
    new_only.is_a?(TrueClass) || new_only.is_a?(FalseClass) end
  def initialize(contents)
    if contents.is_a?(String) then
      contents = JSON.parse(contents.to_str, symbolize_names: true)
    elsif contents.is_a?(ReportSpecification)
      contents = contents.to_hash
    end
    if ! contents.is_a?(Hash) then
      raise "Invalid argument to 'new': #{contents}"
    end
    @response_key = contents[:response_key].to_sym
    if contents[:key_list].is_a?(Enumerable) then
      @key_list = contents[:key_list].map {|e| e.to_sym}
    else
      @key_list = [contents[:key_list]] # I.e., coerce it to an Array.
    end
    @block_msecs = contents[:block_msecs]
    if contents[:new_only].nil? then
      @new_only = false
    else
      @new_only = !! contents[:new_only]
    end
  end

end
