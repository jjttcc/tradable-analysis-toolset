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

  attr_accessible :mas_session_key

  validates :mas_session_key, :presence => true
  validates :user_id, :presence => true

  belongs_to :user

  public ###  Access

  # The last stored user-selected period-type name
  def last_period_type
    data[:last_period_type]
  end

  # The last stored tradable symbol list
  def symbols
    data[:symbols]
  end

  # The stored period-type-name list
  def period_types
    data[:period_types]
  end

  public ###  Status setting

  type :in => String
  pre :valid do |t| PeriodTypeConstants.valid_period_type_name(t) end
  def last_period_type=(t)
    data[:last_period_type] = t
  end

  type :in => Array
  def symbols=(list)
    data[:symbols] = list
  end

  type :in => Array
  def period_types=(list)
    data[:period_types] = list
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
