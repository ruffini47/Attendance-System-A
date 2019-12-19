class AddBusinessProcessingInfoToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :cl_business_processing, :string
    add_column :attendances, :cr_business_processing, :string
  end
end
