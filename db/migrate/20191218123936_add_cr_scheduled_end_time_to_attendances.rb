class AddCrScheduledEndTimeToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :cr_scheduled_end_time, :datetime
  end
end
