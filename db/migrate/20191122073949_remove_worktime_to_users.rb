class RemoveWorktimeToUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :work_time, :datetime
  end
end
