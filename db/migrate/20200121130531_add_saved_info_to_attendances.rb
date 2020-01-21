class AddSavedInfoToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :saved_attendance_change_note, :string
    add_column :attendances, :saved_after_change_start_time, :datetime
    add_column :attendances, :saved_after_change_end_time, :datetime
  end
end
