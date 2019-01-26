=begin
name: varchar
fqdn: varchar DEFAULT '' NOT NULL
port: integer NOT NULL
!!!!TO-DO: status:integer {alive, not_responding, ...}
!!!!possible other TO-DOs:
!!in_use: boolean (or: enabled: boolean[?])
!!(or some similar way of keeping track of whether the MasSocketAddress is
!! supposed to be used, if it's "alive" (the mas server can be reached), or
!! if it's "dead" server not running or can't be reached, or whatever other
!! possible states or recordable problems can occur!!!!!!
=end

# Socket addresses to be used to connect to MAS server processes
# msa.fqdn.empty? implies that the server is running on the local machine.
class MasSocketAddress < ApplicationRecord
=begin
!!!![or (in_use&status are probably better):]TO-DO:!!!!
  enum status {
    enabled:  1,
    disabled: 2,
    running:  3,
    #...
  }
=end
end
