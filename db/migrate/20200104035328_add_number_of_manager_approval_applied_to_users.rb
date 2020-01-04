class AddNumberOfManagerApprovalAppliedToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :number_of_manager_approval_applied, :integer, default: 0
  end
end
