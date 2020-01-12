class AddSavedAttendanceChangeToSuperiorUserIdToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :saved_attendance_change_to_superior_user_id, :integer
  end
end
