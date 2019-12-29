class AddTempAttendanceChangeInfoToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :temp_after_change_start_time, :datetime
    add_column :attendances, :temp_after_change_end_time, :datetime
    add_column :attendances, :temp_attendance_change_note, :string
  end
end
