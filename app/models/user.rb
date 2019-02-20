# == Schema Information
#
# Table name: users
#
#  id                 :integer          not null, primary key
#  email_addr         :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  encrypted_password :string(255)
#  salt               :string(255)
#  admin              :boolean          default(FALSE)
#

require 'digest'
require 'ruby_contracts'

class User < ApplicationRecord
  include Contracts::DSL

  public

  attr_accessor   :password

#!!!!!NOTE: "period_type_specs" needs to go!!!!!:
  has_many :period_type_specs,                       dependent: :destroy
  has_many :analysis_schedules,                      dependent: :destroy
  has_many :analysis_profile_runs,                   dependent: :destroy
  has_many :analysis_profiles, as: :analysis_client, dependent: :destroy
=begin
# We might soon also need:
  has_many :tradable_indicators,   :dependent => :destroy[future-maybe]
=end
  # All notification_addresses owned by this user:
  has_many :notification_addresses,                  dependent: :destroy
  has_many :notifications,                           dependent: :destroy
  has_one  :mas_session,                             dependent: :destroy

  validates :email_addr, :presence       => true,
                         :uniqueness     => { :case_sensitive => false }
  validates_format_of :email_addr, :with =>
    /\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/
  validates :password, :presence => true,
                       :confirmation => true,
                       :length => { :within => 8..64 }
  before_save :encrypt_password

  public  ###  Access

  # Effective name of the user
  alias_attribute :name, :email_addr

  # "myself"
  def user
    self
  end

  # Elements of 'period_type_specs' that specify short durations
  type out: Array
  pre :invariant do invariant end
  post :result_exists do |result| result != nil end
  post :invariant do invariant end
  def analysis_specs
    result = period_type_specs.select do |spec|
      spec.for_analysis?
    end
  end

  # Elements of 'period_type_specs' that specify long durations - that is,
  # those that tend to be used for charting.
  type out: Array
  pre :invariant do invariant end
  post :result_exists do |result| result != nil end
  post :invariant do invariant end
  def charting_specs
    result = period_type_specs.select do |spec|
      ! spec.for_analysis?
    end
  end

  public  ###  Status report

  # Is this user currently in use - i.e., active?
  def active?
    true
  end

  ###  Validation

  # Does 'submitted_pw' match 'password'?
  type :in => String
  def password_matches?(submitted_pw)
    password == submitted_pw
    encrypted_password == encrypted(submitted_pw)
  end

  # The authenticated user, retrieved from the database, identified by
  # 'email', 'submitted_pw' - nil if no such user is found.
  def self.authenticated(email, submitted_pw)
    result = nil
    u = find_by_email_addr(email)
    if u != nil and u.password_matches?(submitted_pw)
      result = u
    end
    result
  end

  def self.authenticated_with_salt(id, cookie_salt)
    result = nil
    user = find_by_id(id)
    if user != nil && user.salt == cookie_salt
      user
    end
    result
  end

  private

  # Encrypt the 'password' attribute.
  def encrypt_password
    if new_record?
      self.salt = new_salt
    end
    self.encrypted_password = encrypted(password)
  end

  # 's' encrypted
  type :in => String, :out => String
  post :result_exists do |result| result != nil && ! result.empty? end
  def encrypted(s)
    secure_hash("#{salt}--#{s}")
  end

  def secure_hash(str)
    Digest::SHA2.hexdigest(str)
  end

  def new_salt
    secure_hash("#{Time.current.utc}--#{password}")
#!!!!    secure_hash("#{Time.now.utc}--#{password}")
  end

  def invariant
    period_type_specs != nil
  end

end
