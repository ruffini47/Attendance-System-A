class AddAttendanceChangeTomorrowInstructorConfirmationToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :attendance_change_tomorrow, :integer
    add_column :attendances, :attendance_change_instructor_confirmation, :integer, default: 0
  end
end
