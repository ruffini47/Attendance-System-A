class RemoveDepartmentFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :department, :string
    remove_column :users, :basic_time, :datetime
    remove_column :users, :work_finish_time, :datetime
    remove_column :users, :work_start_time, :datetime
  end
end
