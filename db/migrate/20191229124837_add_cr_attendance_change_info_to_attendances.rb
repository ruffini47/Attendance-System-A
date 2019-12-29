class AddCrAttendanceChangeInfoToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :cr_after_change_end_time, :datetime
    add_column :attendances, :cr_attendance_change_note, :string
  end
end
