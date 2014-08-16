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

  attr_accessible :mas_session_key, :data
  #!!!!!!!!!!attr_reader :mas_client, :mas_session_key
  validates :mas_session_key, :presence => true
  validates :user_id, :presence => true

  belongs_to :user

end
