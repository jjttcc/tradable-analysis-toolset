=begin
### attributes:

# The profile name
name

# Should analysis results for the run be saved to the database?
save_results
=end

# Profiles for analysis runs of one or more event_generation_profiles, each
# of which has a separate start and end date/time - can be scheduled for
# future analysis runs or run immediately
class AnalysisProfile < ApplicationRecord
  include Contracts::DSL

  public

  belongs_to :analysis_client, polymorphic: true
  has_many   :event_generation_profiles, dependent: :destroy
  # (many-to-many: AnalysisProfile <=> NotificationAddress:)
  has_many   :address_assignments, as: :address_user
  has_many   :notification_addresses, through: :address_assignments
  # (AnalysisProfile  has-one: SymbolList:)
  has_one    :symbol_list_assignment, as: :symbol_list_user
  has_one    :symbol_list, through: :symbol_list_assignment
  #!!!!This might go away:
  has_many   :notifications, as: :notification_source, dependent: :destroy
  has_many   :analysis_profile_runs

  # The last AnalysisProfileRun resulting from analysis based on self's specs
  attr_accessor :last_analysis_profile_run

  public  ###  Access

  # The user/owner of this AnalysisProfile
  post :exists do |result| result != nil end
  def user
    analysis_client.user
  end

  # Name of the client "requesting" an analysis run
  post :exists do |result| result != nil end
  def client_name
    analysis_client.name
  end

  # Array of TradableSymbol objects used by self
  post :empty_if_unused do |result| implies(! in_use?, result.empty?) end
  post :matches_symbol_list_if_used do |result|
    implies(in_use?, result.count == symbol_list.symbols.count) end
  def tracked_tradables
    result = []
    if in_use? then
      result = TradableSymbol.find(symbol_list.symbols)
    end
    result
  end

  # Array of id of: TradableSymbol-objects used by self
  post :empty_if_unused do |result| implies(! in_use?, result.empty?) end
  post :matches_symbol_list_if_used do |result|
    implies(in_use?, result == symbol_list.symbols) end
  def tracked_tradable_ids
    result = []
    if in_use? then
      result = symbol_list.symbols
    end
    result
  end

  # Array of AnalysisRun, from the event_generation_profiles, of the last
  # analysis run (empty if no analysis was performed)
  def last_analysis_runs
    result = event_generation_profiles.select do |p|
      ! p.last_analysis_run.nil?
    end.collect do |p|
      p.last_analysis_run
    end
    result
  end

  # The "AnalysisEvent"s, from event_generation_profiles, resulting from
  # analysis performed on the tradable with symbols: s
  # Empty if no analysis was performed for tradable 's'
  def events_for_symbol(s)
    result = []
    event_generation_profiles.each do |p|
      if ! p.events_for_symbol(s).nil? then
        result.concat(p.events_for_symbol(s))
      end
    end
  end

  public  ###  Status report

  # Is this AnalysisProfile currently in use?
  def in_use?
    analysis_client.active?
  end

end
