class RemoveMasSessionIdFromTradableAnalyzers < ActiveRecord::Migration[5.0]
  def change
    remove_column :tradable_analyzers, :mas_session_id, :integer
  end
end
