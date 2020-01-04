class AddManagerApprovalInfoToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :manager_approval_applying, :boolean, default: false
    add_column :attendances, :manager_approval_to_superior_user_id, :integer
  end
end
