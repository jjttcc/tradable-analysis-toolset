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

class User < ActiveRecord::Base
  attr_accessor   :password, :password_confirmation
  attr_accessible :email_addr, :password, :password_confirmation

  validates :email_addr, :presence       => true,
                         :uniqueness     => { :case_sensitive => false }
  validates_format_of :email_addr, :with =>
    /\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/
  validates :password, :presence => true,
                       :confirmation => true,
                       :length => { :within => 8..64 }
end
