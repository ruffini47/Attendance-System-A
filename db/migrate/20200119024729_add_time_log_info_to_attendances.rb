class AddTimeLogInfoToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :before_change_start_time, :datetime
    add_column :attendances, :before_change_end_time, :datetime
    add_column :attendances, :time_log_count, :integer, default: 0
  end
end
