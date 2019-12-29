class AddAttendanceChangeNoteToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :attendance_change_note, :string
  end
end
