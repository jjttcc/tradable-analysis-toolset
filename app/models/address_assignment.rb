# Model for join table mapping address_users (polymorphic) to
# notification_addresses
class AddressAssignment < ApplicationRecord
  public

  belongs_to :address_user, polymorphic: true
  belongs_to :notification_address
end
