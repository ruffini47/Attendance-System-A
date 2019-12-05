class AddNumberOfOvertimeApplicationToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :number_of_overtime_application, :integer, default: 0
  end
end
