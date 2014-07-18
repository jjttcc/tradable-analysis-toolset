# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  email_addr :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "test_helper"

class UserTest < ActiveSupport::TestCase

  def user
    @user ||= User.new
  end

  def test_valid
    assert user.valid?
  end

end
