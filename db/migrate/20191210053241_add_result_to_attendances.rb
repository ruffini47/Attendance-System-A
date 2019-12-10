class AddResultToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :result, :string
  end
end
