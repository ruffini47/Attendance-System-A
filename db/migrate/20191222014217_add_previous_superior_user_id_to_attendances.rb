class AddPreviousSuperiorUserIdToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :previous_superior_user_id, :integer
  end
end
