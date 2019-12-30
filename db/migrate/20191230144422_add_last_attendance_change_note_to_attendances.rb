class AddLastAttendanceChangeNoteToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :last_attendance_change_note, :string
  end
end
