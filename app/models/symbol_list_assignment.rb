# Assignments of a symbol-list to a symbol-list-user - e.g., to a User, or
# to an AnalysisProfile (corresponds to join table)
class SymbolListAssignment < ApplicationRecord
  public

  belongs_to :symbol_list_user, polymorphic: true
  belongs_to :symbol_list
end
