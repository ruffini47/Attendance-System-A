class AddAfterTimeInfoToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :after_change_start_time, :datetime
    add_column :attendances, :after_change_end_time, :datetime
  end
end
