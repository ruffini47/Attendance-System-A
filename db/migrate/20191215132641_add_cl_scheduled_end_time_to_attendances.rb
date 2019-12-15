class AddClScheduledEndTimeToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :cl_scheduled_end_time, :datetime
  end
end
