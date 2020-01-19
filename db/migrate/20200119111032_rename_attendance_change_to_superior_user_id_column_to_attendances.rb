class RenameAttendanceChangeToSuperiorUserIdColumnToAttendances < ActiveRecord::Migration[5.1]
  def change
    rename_column :attendances, :attendance_change_to_superior_user_id, :temp_attendance_change_to_superior_user_id  
  end
end
