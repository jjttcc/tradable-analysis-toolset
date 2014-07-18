# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  email_addr :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User < ActiveRecord::Base
  attr_accessible :email_addr

  validates :email_addr, :presence       => true,
                         :uniqueness     => { :case_sensitive => false }
  validates_format_of :email_addr, :with =>
    /\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/
end
