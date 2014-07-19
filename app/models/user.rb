# == Schema Information
#
# Table name: users
#
#  id                 :integer          not null, primary key
#  email_addr         :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  encrypted_password :string(255)
#

require 'digest'
require 'ruby_contracts'

class User < ActiveRecord::Base
  include Contracts::DSL

  public

  attr_accessor   :password, :password_confirmation
  attr_accessible :email_addr, :password, :password_confirmation

  validates :email_addr, :presence       => true,
                         :uniqueness     => { :case_sensitive => false }
  validates_format_of :email_addr, :with =>
    /\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/
  validates :password, :presence => true,
                       :confirmation => true,
                       :length => { :within => 8..64 }
  before_save :encrypt_password

  public

  # Does 'submitted_pw' match 'password'?
  type :in => String
  pre :arg_exists do |subpw| ! subpw.blank? end
  def password_matches?(submitted_pw)
    password == submitted_pw
    encrypted_password == encrypted(submitted_pw)
  end

  # Authenticate - return the user with 'email', 'submitted_pw' (password)
  # or, if no match is found, nil.
  def self.authenticate(email, submitted_pw)
    result = nil
    u = find_by_email_addr(email)
    if u != nil and u.password_matches?(submitted_pw)
      result = u
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
  def encrypted(s)
    secure_hash("#{salt}--#{s}")
  end

  def secure_hash(str)
    Digest::SHA2.hexdigest(str)
  end

  def new_salt
    secure_hash("#{Time.now.utc}--#{password}")
  end

end
