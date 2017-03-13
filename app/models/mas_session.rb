# == Schema Information
#
# Table name: mas_sessions
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  mas_session_key :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  data            :text
#

require 'ruby_contracts'

class MasSession < ActiveRecord::Base
  include Contracts::DSL

  public

  validates :mas_session_key, :presence => true
  validates :user_id, :presence => true

  belongs_to :user

  public ###  Access

  # The last stored user-selected period-type name
  post :result_is_string do |result| result.nil? || result.class == String end
  def last_period_type
    data[:last_period_type]
  end

  # The last stored tradable symbol list
  post :result_is_array do |result| result.nil? || result.class == Array end
  def symbols
    data[:symbols]
  end

  # The stored period-type-name list
  post :result_is_array do |result| result.nil? || result.class == Array end
  def period_types
    data[:period_types]
  end

  # The stored analyzer table
  post :result_is_hash do |result| result.nil? || result.class == Hash end
  def analyzers
    data[:anas]
  end

  public ###  Element change

  type :in => String
  pre :arg_exists do |t| t != nil end
  pre :valid do |t| PeriodTypeConstants.valid_period_type_name(t) end
  def last_period_type=(t)
    data[:last_period_type] = t
  end

  type :in => Array
  pre :arg_exists do |list| list != nil end
  def symbols=(list)
    data[:symbols] = list
  end

  type :in => Array
  pre :arg_exists do |list| list != nil end
  def period_types=(list)
    data[:period_types] = list
  end

  type :in => Array
  pre :arg_exists do |list| list != nil end
  pre :has_name do |list| list.all? {|item| item.respond_to?(:name)} end
  post :is_hash do data[:anas].class == Hash end
  def analyzers=(list)
    analyzer_tbl = {}
    list.each do |a|
      analyzer_tbl[a.name] = a
    end
    data[:anas] = analyzer_tbl
  end

  private

  serialize :data, Hash

  def data
    self[:data]
  end

  def data=(val)
    write_attribute :data, val
  end

end
