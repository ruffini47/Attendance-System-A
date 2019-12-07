class AddToSuperiorUserIdToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :to_superior_user_id, :integer
  end
end
