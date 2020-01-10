class AddManagerApprovalToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :manager_approval, :string, default: "所属長承認　未"
  end
end
