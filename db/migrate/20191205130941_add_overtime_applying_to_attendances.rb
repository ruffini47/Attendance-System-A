class AddOvertimeApplyingToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overtime_applying, :boolean, default: false
  end
end
