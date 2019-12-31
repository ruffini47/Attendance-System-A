class AddCrAfterChangeStartTimeToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :cr_after_change_start_time, :datetime
  end
end
