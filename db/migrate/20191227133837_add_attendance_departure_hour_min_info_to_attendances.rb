class AddAttendanceDepartureHourMinInfoToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :attendance_hour, :integer
    add_column :attendances, :attendance_min, :integer
    add_column :attendances, :departure_hour, :integer
    add_column :attendances, :departure_min, :integer
  end
end
