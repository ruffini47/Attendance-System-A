class AddManagerApprovalInstructorConfirmationToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :manager_approval_instructor_confirmation, :integer, default: 0
  end
end
