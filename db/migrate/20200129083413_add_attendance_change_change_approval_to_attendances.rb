class AddAttendanceChangeChangeApprovalToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :attendance_change_change_approval, :boolean
  end
end
