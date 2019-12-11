class AddTemporaryInfoToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :temp_scheduled_end_time, :datetime
    add_column :attendances, :temp_business_processing, :string
  end
end
