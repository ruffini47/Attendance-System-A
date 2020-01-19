class AddTimeLogAttendanceChangeApprovedToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :time_log_attendance_change_approved, :boolean, default: false
  end
end
