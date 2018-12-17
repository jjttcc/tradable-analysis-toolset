=begin
label: varchar (NOT NULL)
medium_type: integer (NOT NULL)
contact_identifier: varchar (NOT NULL)
extra_data: varchar
=end


# Addresses used for "notifications" (by email, text, or etc.)
class NotificationAddress < ApplicationRecord
  public

  belongs_to :user
  has_many :address_assignments

  def address_users
    address_assignments.map {|aa| aa.address_user }
  end

  enum medium_type: {
    email:      1,
    text:       2,
    telephone:  3,
    #...
  }

end
