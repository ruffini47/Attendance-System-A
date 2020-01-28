class AddChangeApprovalToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :change_approval, :boolean
  end
end
