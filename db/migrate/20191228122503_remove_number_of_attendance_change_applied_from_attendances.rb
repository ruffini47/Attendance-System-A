class RemoveNumberOfAttendanceChangeAppliedFromAttendances < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :number_of_attendance_change_applied, :integer
  end
end
