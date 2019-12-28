class AddNumberOfAttendanceChangeAppliedToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :number_of_attendance_change_applied, :integer, default: 0
  end
end
