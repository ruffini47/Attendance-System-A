class AddManagerApprovalChangeApprovalToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :manager_approval_change_approval, :boolean
  end
end
