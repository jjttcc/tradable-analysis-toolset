class RemoveEventTypeIdFromAnalysisEvents < ActiveRecord::Migration[5.0]
  def change
    remove_column :analysis_events, :event_type_id
  end
end
